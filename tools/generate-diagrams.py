#!/usr/bin/env python3

import argparse
import logging

#from diagrams import Cluster, Diagram, Edge, getdiagram
#from diagrams.generic.blank import Blank
#from diagrams.generic.virtualization import Vmware
#from diagrams.onprem.ci import ZuulCI
#from diagrams.onprem.client import Client
#from diagrams.onprem.compute import Server
#from diagrams.onprem.database import Postgresql
#from diagrams.onprem.monitoring import Grafana
#from diagrams.onprem.network import HAProxy
#from diagrams.openstack import _OpenStack
#from diagrams.openstack.compute import Nova
#from diagrams.openstack.networking import Neutron
#from diagrams.openstack.networking import Octavia
#from diagrams.openstack.storage import Swift

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

    #print(dot.source)
    dot.render(f'{path}/reverse_proxy', view=False)

    #with Diagram(
    #    "Reverse Proxy", show=False, outformat='svg',
#   #     direction="TB",
    #    filename=f'{path}/reverse_proxy2',
    #    graph_attr=graph_attr,
    #    node_attr=node_attr
    #) as dia:
    #    client = Client("User", **node_attr)
    #    lb = Octavia("Load Balancer", **node_attr)
    #    gw = Vmware("Vcloud Gateway", **node_attr)
    #    client >> lb
    #    client >> gw
    #    proxies = []
    #    host_vars = None
    #    with Cluster("ReverseProxy") as prox:
    #        for host in inventory.groups['proxy'].get_hosts():
    #            host_vars = variable_manager.get_vars(
    #                host=host)
    #            host = HAProxy(
    #                    host_vars['inventory_hostname_short'],
    #                    tooltip=host_vars['inventory_hostname']
    #            )
    #            proxies.append(host)
    #            provider = host_vars.get('location', {}).get('provider', {})
    #            if provider == 'otc':
    #                lb >> host
    #            elif provider == 'vcloud':
    #                gw >> host

    #    with Cluster("Apps") as apps:
    #        # host_vars still points to the last proxy host
    #        app_node_attr = {
    #            'shape': 'box',
    #            'height': '0.5',
    #        }
    #        for _app in host_vars['proxy_backends']:
    #            app = Blank(_app['name'], **app_node_attr)
    #            proxies[len(proxies) // 2] - Edge(lhead=prox.name, ltail=apps.name) - app

    #    print(dia.dot.source)

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


if __name__ == '__main__':
    main()
