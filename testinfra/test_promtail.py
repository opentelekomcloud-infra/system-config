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

testinfra_hosts = ['promtail.focal']

def test_promtail_container_listening(host):
    sock = host.socket("tcp://0.0.0.0:3101")
    assert sock.is_listening


def test_promtail_systemd(host):
    service = host.service('promtail')
    assert service.is_enabled
