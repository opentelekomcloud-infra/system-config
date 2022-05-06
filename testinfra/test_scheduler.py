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

testinfra_hosts = ['scheduler.centos-stream', 'scheduler.focal']


def test_scheduler_config(host):
    config = host.file('/etc/apimon/apimon.yaml')
    secure_config = host.file('/etc/apimon/apimon-secure.yaml')
    assert config.exists
    assert secure_config.exists

    assert b'test_alerta_endpoint' in config.content
    assert b'alerta_token' in secure_config.content

    assert b'test_projects:' in config.content

    assert b'test_matrix' in config.content


def test_scheduler_systemd(host):
    service = host.service('apimon-scheduler')
    assert service.is_enabled
