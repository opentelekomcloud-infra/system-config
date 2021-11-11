#!/usr/bin/env python3

import argparse
import logging

from diagrams import Cluster, Diagram, Edge, getdiagram
from diagrams.generic.blank import Blank
from diagrams.onprem.ci import ZuulCI
from diagrams.onprem.client import Client
from diagrams.onprem.compute import Server
from diagrams.onprem.database import Postgresql
from diagrams.onprem.monitoring import Grafana
from diagrams.onprem.network import HAProxy
from diagrams.openstack import _OpenStack
from diagrams.openstack.compute import Nova
from diagrams.openstack.networking import Neutron
from diagrams.openstack.networking import Octavia
from diagrams.openstack.storage import Swift

import graphviz

from ansible.parsing.dataloader import DataLoader
from ansible.inventory.manager import InventoryManager as _InventoryManager
from ansible.plugins.loader import inventory_loader
from ansible.vars.manager import VariableManager
from ansible.utils.display import Display

display = Display(verbosity=40)

graph_attr = {
    "fontsize": "10",
    "bgcolor": "transparent",
    "pad": "0",
    "splines": "curved"
}
node_attr = {
    'fontsize': '10',
    'shape': 'box',
    'height': '1.3',
    'width': '1',
    'imagescale': 'true'
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
    with Diagram(
        "Reverse Proxy", show=False, outformat='svg',
        direction="TB",
        filename=f'{path}/reverse_proxy',
        graph_attr=graph_attr,
        node_attr=node_attr
    ) as dia:
        lb = Octavia("Load Balancer", **node_attr)
        client = Client("User", **node_attr)
        client >> lb
        proxies = []
        host_vars = None
        with Cluster("ReverseProxy") as prox:
            for host in inventory.groups['proxy'].get_hosts():
                host_vars = variable_manager.get_vars(
                    host=host)
                proxies.append(
                    HAProxy(
                        host_vars['inventory_hostname_short'],
                        tooltip=host_vars['inventory_hostname'])
                )
            lb >> proxies

        with Cluster("Apps") as apps:
            # host_vars still points to the last proxy host
            app_node_attr = {
                'shape': 'box',
                'height': '0.5',
            }
            for _app in host_vars['proxy_backends']:
                app = Blank(_app['name'], **app_node_attr)
                proxies[len(proxies) // 2] - Edge(lhead=prox.name, ltail=apps.name) - app

        print(dia.dot.source)

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
