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

testinfra_hosts = ['epmon.f32', 'epmon.focal']


def test_epmon_config(host):
    config = host.file('/etc/apimon/apimon.yaml')
    secure_config = host.file('/etc/apimon/apimon-secure.yaml')
    assert config.exists
    assert secure_config.exists

    assert b'test_alerta_endpoint' in config.content
    assert b'alerta_token' in secure_config.content
    hostname = host.ansible.get_variables()['inventory_hostname']
    if hostname == 'epmon.f32':
        assert b'zone: zone_f32' in config.content
    elif hostname == 'epmon.focal':
        assert b'zone: zone_focal' in config.content

    assert b'host: 1.2.3.4' in config.content


def test_epmon_systemd(host):
    service = host.service('apimon-epmon')
    assert service.is_enabled
