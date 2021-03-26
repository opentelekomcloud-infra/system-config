# Copyright 2020 Red Hat, Inc.
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
import json
import logging
import ssl
import urllib.request

testinfra_hosts = ['graphite1.focal', 'graphite2.centos']


def test_graphite_container_web_listening(host):
    graphite_http = host.socket("tcp://0.0.0.0:8081")
    assert graphite_http.is_listening

    #graphite_https = host.socket("tcp://127.0.0.1:443")
    #assert graphite_https.is_listening

def test_graphite(host):
    cmd = host.run('curl --insecure '
                   '--resolve graphite1.focal:8081:127.0.0.1 '
                   'http://graphite1.focal:8081')
    assert '<title>Graphite Browser</title>' in cmd.stdout

def test_graphite_data(host):
    # seed some data; send it over ipv6
    cmd = ('timeout 20 bash -c '
           '\'while true; do echo -n "example:$((RANDOM % 100))|c" '
           '| nc -6 -w 1 -u localhost 8125; done\'')
    host.run(cmd)

    url='render?from=-10mins&until=now&target=stats.example&format=json'

    # Assert we see some non-null values for this stat
    # multi-node-hosts-file has setup graphite1.focal to
    # resolve from hosts.
    found_value = False
    with urllib.request.urlopen('http://graphite1.focal:8081/%s' % (url),
#                                context=ssl._create_unverified_context()
                               ) \
                                as req:
        data = json.loads(req.read().decode())
        logging.debug('got: %s' % data)
        datapoints = (data[0]['datapoints'])
        for p in datapoints:
            if p[0] != None:
                found_value = True

    assert found_value
