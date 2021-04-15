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
testinfra_hosts = ['le1']


def test_cert_exists(host):
    for f in ['csr', 'pem', 'crt']:
        crt_file = host.file('/etc/ssl/le1/fake-domain.%s' % f)
        assert crt_file.exists

    haproxy_cert = host.file('/etc/ssl/le1/haproxy/fake-domain.pem')
    assert haproxy_cert.exists
