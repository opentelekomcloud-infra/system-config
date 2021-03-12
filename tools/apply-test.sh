#!/bin/bash -ex

# Copyright 2014 Hewlett-Packard Development Company, L.P.
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

. ./tools/prep-apply.sh

if [[ ! -d applytest ]] ; then
    mkdir ~/applytest
fi

trap "sudo mv ~/applytest applytest" EXIT

# Split the class defs.
csplit -sf ~/applytest/puppetapplytest $PUPPET_MANIFEST '/^}$/' {*}
# Remove } header left by csplit
sed -i -e '/^\}$/d' ~/applytest/puppetapplytest*
# Comment out anything that doesn't begin with a space.
# This gives us the node {} internal contents.
sed -i -e 's/^[^][:space:]$]/#&/g' ~/applytest/puppetapplytest*
sed -i -e 's@hiera(.\([^.]*\).,\([^)]*\))@\2@' ~/applytest/puppetapplytest*
sed -i -e "s@hiera(.\([^.]*\).)@'\1NoDefault'@" ~/applytest/puppetapplytest*

if [[ `lsb_release -i -s` == 'CentOS' ]]; then
    if [[ `lsb_release -r -s` =~ '7' ]]; then
        CODENAME='centos7'
    fi
elif [[ `lsb_release -i -s` == 'Debian' ]]; then
    CODENAME=`lsb_release -c -s`
elif [[ `lsb_release -i -s` == 'Ubuntu' ]]; then
    CODENAME=`lsb_release -c -s`
elif [[ `lsb_release -i -s` == 'Fedora' ]]; then
    REL=`lsb_release -r -s`
    CODENAME="fedora$REL"
fi

FOUND=0
for f in `find ~/applytest -name 'puppetapplytest*' -print` ; do
    if grep -q "Node-OS: $CODENAME" $f; then
        if grep -q "Puppet-Version: !${PUPPET_VERSION}" $f; then
            echo "Skipping $f due to unsupported puppet version"
            continue
        else
            cp $f $f.final
            FOUND=1
        fi
    fi
done

if [[ $FOUND == "0" ]]; then
    echo "No hosts found for node type $CODENAME"
    exit 1
fi

cat > ~/applytest/primer.pp << EOF
class helloworld {
  notify { 'hello, world!': }
}
EOF

sudo mkdir -p /var/run/puppet
echo "Running apply test primer to avoid setup races when run in parallel."
./tools/test_puppet_apply.sh ~/applytest/primer.pp

THREADS=$(nproc)
if grep -qi centos /etc/os-release ; then
    # Single thread on centos to workaround a race with rsync on centos
    # when copying puppet modules for multiple puppet applies at the same
    # time.
    THREADS=1
fi

echo "Running apply test on these hosts:"
find ~/applytest -name 'puppetapplytest*.final' -print0
find ~/applytest -name 'puppetapplytest*.final' -print0 | \
    xargs -0 -P $THREADS -n 1 -I filearg \
        ./tools/test_puppet_apply.sh filearg
