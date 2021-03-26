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
import memcache

testinfra_hosts = ['memcached.focal']


def test_memcached_container_listening(host):
    sock = host.socket("tcp://0.0.0.0:11211")
    assert sock.is_listening


def test_memcached_data(host):
    client = memcache.Client(["{0}:{1}".format('memcached.focal', 11211)])
    sample_obj = {"foo": "bar"}
    client.set("foo", "bar", time=15)
    check = client.get("foo")
    assert check == "bar"


def test_memcached_systemd(host):
    service = host.service('memcached')
    assert service.is_enabled
