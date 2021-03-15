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
import platform
import pytest

testinfra_hosts = ['bridge.eco.tsi-dev.otc-service.com']


def test_zuul_data(host, zuul_data):
    # Test the zuul_data fixture that picks up things set by Zuul
    assert 'inventory' in zuul_data
    assert 'extra' in zuul_data
    assert 'zuul' in zuul_data['extra']


def test_clouds_yaml(host):
    clouds_yaml = host.file('/etc/openstack/clouds.yaml')
    assert clouds_yaml.exists

    assert b'password' in clouds_yaml.content


def test_openstacksdk_config(host):
    f = host.file('/etc/openstack')
    assert f.exists
    assert f.is_directory
    assert f.user == 'root'
    assert f.group == 'root'
    assert f.mode == 0o750
    del f


def test_root_authorized_keys(host):
    authorized_keys = host.file('/root/.ssh/authorized_keys')
    assert authorized_keys.exists

    content = authorized_keys.content.decode('utf8')
    lines = content.split('\n')
    assert len(lines) >= 2


def test_kube_config(host):
    if platform.machine() != 'x86_64':
        pytest.skip()
    kubeconfig = host.file('/root/.kube/config')
    assert kubeconfig.exists

    assert b'fake_key_data' in kubeconfig.content


def test_kubectl(host):
    if platform.machine() != 'x86_64':
        pytest.skip()
    kube = host.run('kubectl help')
    assert kube.rc == 0


def test_zuul_authorized_keys(host):
    authorized_keys = host.file('/home/zuul/.ssh/authorized_keys')
    assert authorized_keys.exists

    content = authorized_keys.content.decode('utf8')
    lines = content.split('\n')
    # Remove empty lines
    keys = list(filter(None, lines))
    assert len(keys) >= 2
    for key in keys:
        assert 'ssh-rsa' in key
