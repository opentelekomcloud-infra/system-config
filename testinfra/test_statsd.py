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

testinfra_hosts = ['centos-stream']


def test_statsd_config(host):
    statsd_config = host.file('/etc/statsd/config.js')
    assert statsd_config.exists


def test_statsd_service(host):
    service = host.service('statsd')
    assert service.is_enabled
    assert service.is_running


# Disable this. pulling container might take time or fail at all. We do not
# want to fail CI due to that __for now__.
#def test_port(host):
#    socket = host.socket('udp://8125')
#    assert socket.is_listening
