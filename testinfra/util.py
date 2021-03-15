# Copyright 2018 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import socket

def get_ips(value, family=None):
    ret = set()
    try:
        addr_info = socket.getaddrinfo(value, None, family)
    except socket.gaierror:
        return ret
    for addr in addr_info:
        ret.add(addr[4][0])
    return ret


def verify_firewalld_ports(host):
    ports = host.run('firewall-cmd --list-ports --zone public')
    ports = [x.strip() for x in ports.stdout.split(' ')]

    needed_ports = []

    for port in needed_ports:
        assert port in ports

    return ports


def verify_firewalld_services(host):
    services = host.run('firewall-cmd --list-services --zone public')
    services = [x.strip() for x in services.stdout.split(' ')]

    needed_services = [
        'ssh'
    ]
    for service in needed_services:
        assert service in services

    return services
