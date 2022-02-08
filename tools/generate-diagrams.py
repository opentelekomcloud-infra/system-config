#!/usr/bin/env python3

import argparse
import logging

import graphviz

from ansible.parsing.dataloader import DataLoader
from ansible.inventory.manager import InventoryManager as _InventoryManager
from ansible.plugins.loader import inventory_loader
from ansible.vars.manager import VariableManager


graph_attr = {
    "fontsize": "10",
    "bgcolor": "transparent",
    "pad": "0",
    "splines": "curved"
}
node_attr = {
    #'fontsize': '10',
    'shape': 'box',
    #'height': '1.3',
    #'width': '1',
    'imagescale': 'true'
}
graphviz_graph_attr = {
    'bgcolor': 'transparent',
    'fontcolor': '#2D3436',
    'fontname': 'Sans-Serif',
    'fontsize': '10',
    # 'pad': '0',
    'rankdir': 'LR',
    # 'ranksep': '0.75',
    #'splines': 'curved',
    'compound': 'true' # important for ltail/lhead
}

graphviz_cluster_attrs = {
    'bgcolor': '#E5F5FD',
    'shape': 'box',
    'style': 'rounded'
}

graphviz_icon_node_attrs = {
    'imagescale': 'true',
    'fixedsize': 'true',
    'fontsize': '10',
    'width': '1',
    'height': '1.4',
    'shape':'none',
    'labelloc': 'b',
}


# Override Ansible inventory manager to inject our plugin
class InventoryManager(_InventoryManager):
    def _fetch_inventory_plugins(self):
        plugins = super()._fetch_inventory_plugins()
        inventory_loader.add_directory('playbooks/roles/install-ansible/files/inventory_plugins')
        for plugin_name in ['yamlgroup']:
            plugin = inventory_loader.get(plugin_name)
            if plugin:
                plugins.append(plugin)
        return plugins


def zuul(path, inventory, variable_manager):
    """General Zuul software diagram"""
    g = graphviz.Digraph(
        'Zuul CI/CD',
        graph_attr=graphviz_graph_attr,
        node_attr={'fixedsize': 'false'}
    )
    user = g.node(
        'user', 'Clients',
        image='../_images/users.png',
        **graphviz_icon_node_attrs
    )
    # NOTE: adding elb and user<=>git communication make graph overloaded and
    # and badly placed
    #elb = g.node(
    #    'elb', 'Elastic Load Balancer',
    #    image='../_images/elb-network-load-balancer.png',
    #    **graphviz_icon_node_attrs
    #)
    git = g.node(
        'git', 'Git Provider',
        image='../_images/git.png',
        **graphviz_icon_node_attrs
    )
    #g.edge('user', 'elb')
    #g.edge('git', 'elb')
    #g.edge('user', 'git')

    # NOTE: cluster name must start with "cluster_" for graphviz
    with g.subgraph(
        name='cluster_zuul',
        graph_attr=graphviz_cluster_attrs,
        node_attr={
            'fontsize': '8'
        }
    ) as zuul:
        zuul.attr(label='Zuul CI/CD')

        zuul.node('zuul-web', 'Zuul Web')
        zuul.node('zuul-merger', 'Zuul Merger')
        zuul.node('zuul-executor', 'Zuul Executor')
        zuul.node('zuul-scheduler', 'Zuul Scheduler')
        zuul.node('nodepool-launcher', 'Nodepool Launcher')
        zuul.node('nodepool-builder', 'Nodepool Builder')

    g.node(
        'zookeeper', label='Zookeeper',
        image='../_images/zookeeper.png',
        **graphviz_icon_node_attrs)

    g.edge('zuul-web', 'zookeeper')
    g.edge('zuul-merger', 'zookeeper')
    g.edge('zuul-executor', 'zookeeper')
    g.edge('zuul-scheduler', 'zookeeper')
    g.edge('nodepool-launcher', 'zookeeper')
    g.edge('nodepool-builder', 'zookeeper')
    db = g.node(
        'db', 'SQL Database',
        image='../_images/postgresql.png',
        **graphviz_icon_node_attrs)
    cloud = g.node(
        'cloud', 'Clouds resources',
        image='../_images/openstack.png',
        **graphviz_icon_node_attrs)

    g.edge('user', 'zuul-web')
    g.edge('zuul-merger', 'git')
    g.edge('zuul-executor', 'git')
    g.edge('zuul-web', 'db')
    g.edge('nodepool-launcher', 'cloud')
    g.edge('nodepool-builder', 'cloud')
    g.edge('zuul-executor', 'cloud')

    g.render(f'{path}/zuul', format='svg', view=False)

    zuul_sec(path, inventory, variable_manager)
    zuul_dpl(path, inventory, variable_manager)


def zuul_sec(path, inventory, variable_manager):
    """Zuul security deployment diagram"""
    edge_attrs = {'fontsize': '8'}
    edge_attrs_zk = {'color': 'red', 'label': 'TLS', 'fontsize': '8'}
    edge_attrs_ssh = {'color': 'blue', 'label': 'SSH', 'fontsize': '8'}
    edge_attrs_https = {'color': 'green', 'label': 'HTTPS', 'fontsize': '8'}

    g = graphviz.Digraph(
        'Zuul CI/CD Security Design',
        graph_attr=graphviz_graph_attr,
        node_attr={'fixedsize': 'false'}
    )
    git = g.node(
        'git', 'Git Provider',
        image='../_images/git.png',
        **graphviz_icon_node_attrs
    )
    db = g.node(
        'db', 'SQL Database',
        image='../_images/postgresql.png',
        **graphviz_icon_node_attrs)
    cloud = g.node(
        'cloud', 'Clouds resources',
        image='../_images/openstack.png',
        **graphviz_icon_node_attrs)

    with g.subgraph(
        name='cluster_k8',
        graph_attr=graphviz_cluster_attrs,
        node_attr={
            'fontsize': '8'
        }
    ) as k8:
        k8.attr(label='Kubernetes Cluster')

        with k8.subgraph(
           name='cluster_zuul',
           #graph_attr=graphviz_cluster_attrs
           node_attr={
               'fontsize': '8'
           }
       ) as zuul:
            zuul.attr(label='Zuul Namespace')

            zuul.node('zuul-web', 'Zuul Web')
            zuul.node('zuul-merger', 'Zuul Merger')
            zuul.node('zuul-executor', 'Zuul Executor')
            zuul.node('zuul-scheduler', 'Zuul Scheduler')
            zuul.node('nodepool-launcher', 'Nodepool Launcher')
            zuul.node('nodepool-builder', 'Nodepool Builder')

        with k8.subgraph(
           name='cluster_zk',
           node_attr={
               'fontsize': '8'
           }
        ) as zk:
            zk.attr(label='Zuul Namespace')

            zk.node(
                'zookeeper', label='Zookeeper',
                image='../_images/zookeeper.png',
                **graphviz_icon_node_attrs)

        g.edge('zuul-web', 'zookeeper', **edge_attrs_zk)
        g.edge('zuul-merger', 'zookeeper', **edge_attrs_zk)
        g.edge('zuul-executor', 'zookeeper', **edge_attrs_zk)
        g.edge('zuul-scheduler', 'zookeeper', **edge_attrs_zk)
        g.edge('nodepool-launcher', 'zookeeper', **edge_attrs_zk)
        g.edge('nodepool-builder', 'zookeeper', **edge_attrs_zk)

    g.edge('zuul-merger', 'git', **edge_attrs_ssh)
    g.edge('zuul-executor', 'git', **edge_attrs_ssh)
    g.edge('zuul-web', 'db', label='TLS', **edge_attrs)
    g.edge('nodepool-launcher', 'cloud', **edge_attrs_https)
    g.edge('nodepool-builder', 'cloud', **edge_attrs_https)
    g.edge('zuul-executor', 'cloud', **edge_attrs_ssh)

    g.render(f'{path}/zuul_sec', format='svg', view=False)


def zuul_dpl(path, inventory, variable_manager):
    """ Zuul deployment diagram"""
    edge_attrs_zk = {'color': 'red', 'label': 'TLS', 'fontsize': '8'}
    edge_attrs_vault = {'color': 'blue', 'label': 'TLS', 'fontsize': '8'}

    g = graphviz.Digraph(
        'Zuul CI/CD Deployment Design',
        graph_attr=graphviz_graph_attr,
        node_attr={'fixedsize': 'false'}
    )

    g.node(
        'vault', 'Vault',
        image='../_images/vault.png',
        **graphviz_icon_node_attrs)

    with g.subgraph(
        name='cluster_k8',
        graph_attr=graphviz_cluster_attrs,
        node_attr={
            'fontsize': '8'
        }
    ) as k8:
        k8.attr(label='Kubernetes Cluster')

        with k8.subgraph(
           name='cluster_zuul',
           #graph_attr=graphviz_cluster_attrs
           node_attr={
               'fontsize': '8'
           }
       ) as zuul:
            zuul.attr(label='Zuul Namespace')

            zuul.node('zuul-web', 'Zuul Web')
            zuul.node('zuul-merger', 'Zuul Merger')
            zuul.node('zuul-executor', 'Zuul Executor')
            zuul.node('zuul-scheduler', 'Zuul Scheduler')
            zuul.node('nodepool-launcher', 'Nodepool Launcher')
            zuul.node('nodepool-builder', 'Nodepool Builder')

            g.edge('zuul-web', 'vault', **edge_attrs_vault)
            g.edge('zuul-merger', 'vault', **edge_attrs_vault)
            g.edge('zuul-executor', 'vault', **edge_attrs_vault)
            g.edge('zuul-scheduler', 'vault', **edge_attrs_vault)
            g.edge('nodepool-launcher', 'vault', **edge_attrs_vault)
            g.edge('nodepool-builder', 'vault', **edge_attrs_vault)

        with k8.subgraph(
           name='cluster_zk',
           node_attr={
               'fontsize': '8'
           }
        ) as zk:
            zk.attr(label='Zuul Namespace')

            zk.node(
                'zookeeper', label='Zookeeper',
                image='../_images/zookeeper.png',
                **graphviz_icon_node_attrs)
            g.edge('zookeeper', 'vault', **edge_attrs_vault)

        g.edge('zuul-web', 'zookeeper', **edge_attrs_zk)
        g.edge('zuul-merger', 'zookeeper', **edge_attrs_zk)
        g.edge('zuul-executor', 'zookeeper', **edge_attrs_zk)
        g.edge('zuul-scheduler', 'zookeeper', **edge_attrs_zk)
        g.edge('nodepool-launcher', 'zookeeper', **edge_attrs_zk)
        g.edge('nodepool-builder', 'zookeeper', **edge_attrs_zk)

    g.render(f'{path}/zuul_dpl', format='svg', view=False)


def proxy(path, inventory, variable_manager):
    dot = graphviz.Digraph(
        'Reverse Proxy',
        format='svg',
        graph_attr=graphviz_graph_attr,
        node_attr={'fixedsize': 'false'}
    )
    user = dot.node(
        'user', 'Clients',
        image='../_images/users.png',
        **graphviz_icon_node_attrs
    )
    lb = dot.node(
        'lb', 'Load Balancer',
        tooltip='Load Balancer in OTC',
        **node_attr)
    gw = dot.node(
        'gw', 'Network Gateway',
        tooltip='Network Gateway in vCloud',
        **node_attr)
    dot.edge('user', 'lb')
    dot.edge('user', 'gw')

    proxies = []
    with dot.subgraph(
        name="cluster_proxy",
        graph_attr=graphviz_cluster_attrs
    ) as prox:
        prox.attr(label='Reverse Proxy')
        for host in inventory.groups['proxy'].get_hosts():
            host_vars = variable_manager.get_vars(
                host=host)
            host_name = host_vars['inventory_hostname_short']
            host = prox.node(
                host_name,
                label=host_name,
                tooltip=host_vars['inventory_hostname'],
                image='../_images/haproxy.png',
                **graphviz_icon_node_attrs
            )
            proxies.append(host_name)
            provider = host_vars.get('location', {}).get('provider', {})
            if provider == 'otc':
                dot.edge('lb', host_name)
            elif provider == 'vcloud':
                dot.edge('gw', host_name)

    with dot.subgraph(
        name="cluster_apps",
        graph_attr=graphviz_cluster_attrs
    ) as apps:
        apps.attr(label='Applications')
        edge_from = proxies[len(proxies) // 2]
        _apps = [x['name'] for x in host_vars['proxy_backends']]
        _apps.sort()
        for _app in _apps:
            app = apps.node(_app)
            dot.edge(
                edge_from, _app,
                ltail='cluster_proxy')

    dot.render(f'{path}/reverse_proxy', view=False)


def main():
    logging.basicConfig(level=logging.DEBUG)
    # create parser
    parser = argparse.ArgumentParser()

    # add arguments to the parser
    parser.add_argument(
        "--path",
        default='./',
        help='Path to generate diagrams in'
    )
    # parse the arguments
    args = parser.parse_args()

    loader = DataLoader()
    inventory = InventoryManager(
        loader=loader,
        sources=[
            'inventory/base/hosts.yaml',
            'inventory/service/groups.yaml'
        ])
    variable_manager = VariableManager(
        loader=loader,
        inventory=inventory)

    path = args.path
    proxy(path, inventory, variable_manager)
    zuul(path, inventory, variable_manager)


if __name__ == '__main__':
    main()
