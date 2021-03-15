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

import util

testinfra_hosts = ['all']


def test_firewalld(host):

    firewalld = host.service('firewalld')
    assert firewalld.is_running
    assert firewalld.is_enabled
    ports = util.verify_firewalld_ports(host)
    services = util.verify_firewalld_services(host)

    # Make sure that the zuul console stream rule is still present
    zuul = '19885/tcp'
    assert zuul in ports


def test_ntp(host):
    package = host.package("ntp")
    if host.system_info.distribution in ['fedora', 'centos']:
        package = host.package('chrony')
        assert package.is_installed

        service = host.service('chronyd')
        assert service.is_running
        assert service.is_enabled

    else:
        assert not package.is_installed

        service = host.service('systemd-timesyncd')
        assert service.is_running

        # Focal updates the status string to just say NTP
        if host.system_info.codename == 'bionic':
            stdout_string = 'systemd-timesyncd.service active'
        else:
            stdout_string = 'NTP service: active'
        cmd = host.run("timedatectl status")
        assert stdout_string in cmd.stdout


def test_timezone(host):
    tz = host.check_output('date +%Z')
    assert tz == "UTC"


def test_unbound(host):
    output = host.check_output('host opendev.org')
    assert 'has address' in output


def test_unattended_upgrades(host):
    if host.system_info.distribution in ['ubuntu', 'debian']:
        package = host.package("unattended-upgrades")
        assert package.is_installed

        package = host.package("mailutils")
        assert package.is_installed

        cfg_file = host.file("/etc/apt/apt.conf.d/10periodic")
        assert cfg_file.exists
        assert cfg_file.contains('^APT::Periodic::Enable "1"')
        assert cfg_file.contains('^APT::Periodic::Update-Package-Lists "1"')
        assert cfg_file.contains('^APT::Periodic::Download-Upgradeable-Packages "1"')
        assert cfg_file.contains('^APT::Periodic::AutocleanInterval "5"')
        assert cfg_file.contains('^APT::Periodic::Unattended-Upgrade "1"')
        assert cfg_file.contains('^APT::Periodic::RandomSleep "1800"')

        cfg_file = host.file("/etc/apt/apt.conf.d/50unattended-upgrades")
        assert cfg_file.contains('^Unattended-Upgrade::Mail "root"')

    else:
        package = host.package("dnf-automatic")
        assert package.is_installed

        service = host.service("crond")
        assert service.is_enabled
        assert service.is_running

        cfg_file = host.file("/etc/dnf/automatic.conf")
        assert cfg_file.exists
        assert cfg_file.contains('apply_updates = yes')


def test_logrotate(host):
    '''Check for log rotation configuration files

       The magic number here is [0:5] of the sha1 hash of the full
       path to the rotated logfile; the role adds this for uniqueness.
    '''
    ansible_vars = host.ansible.get_variables()
    if ansible_vars['inventory_hostname'] == 'bridge.eco.tsi-dev.otc-service.com':
        cfg_file = host.file("/etc/logrotate.d/ansible.log.37237.conf")
        assert cfg_file.exists
        assert cfg_file.contains('/var/log/ansible/ansible.log')


def test_no_recommends(host):
    if host.system_info.distribution in ['ubuntu', 'debian']:
        cfg_file = host.file("/etc/apt/apt.conf.d/95disable-recommends")
        assert cfg_file.exists

        assert cfg_file.contains('^APT::Install-Recommends "0"')
        assert cfg_file.contains('^APT::Install-Suggests "0"')
