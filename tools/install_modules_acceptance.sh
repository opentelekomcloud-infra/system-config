#!/bin/bash -ex

# Copyright 2015 Hewlett-Packard Development Company, L.P.
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

# This script installs the puppet modules required by infra to run acceptance
# tests. It can run in two different contexts. In the first case, it is running
# as part of a zuul driven check/gate queue where it needs to opportunisticly
# install patches to repositories that are not landed yet. In the second case,
# it is running from a base virtual machine by the beaker tooling where it needs
# to install master of all openstack-infra repos and the tagged versions of all
# library modules.

# This script uses system-config/modules.env as the source of truth for modules
# to install. It detects the presence of /home/zuul to decide if we are running
# in a zuul environment or not.

ROOT=$(readlink -fn $(dirname $0)/..)

# These arrays are initialized here and populated in modules.env

# Array of modules to be installed key:value is module:version.
declare -A MODULES

# Array of modues to be installed from source and without dependency resolution.
# key:value is source location, revision to checkout
declare -A SOURCE_MODULES

# Array of modues to be installed from source and without dependency resolution from openstack git
# key:value is source location, revision to checkout
declare -A INTEGRATION_MODULES

install_external() {
    PUPPET_INTEGRATION_TEST=1 ${ROOT}/install_modules.sh
}

install_openstack() {
    local modulepath
    if [ "$PUPPET_VERSION" == "3" ] ; then
        modulepath='/etc/puppet/modules'
    else
        modulepath='/etc/puppetlabs/code/modules'
    fi

    sudo -E git clone /home/zuul/src/opendev.org/openstack/project-config /etc/project-config

    project_names=""
    source ${ROOT}/modules.env
    for MOD in ${!INTEGRATION_MODULES[*]}; do
        project_scope=$(basename $(dirname $MOD))
        repo_name=$(basename $MOD)
        short_name=$(echo $repo_name | cut -f2- -d-)
        sudo -E git clone /home/zuul/src/opendev.org/$project_scope/$repo_name $modulepath/$short_name
    done
}

install_all() {
    PUPPET_INTEGRATION_TEST=0 ${ROOT}/install_modules.sh

}

if [ -d /home/zuul/src/opendev.org ] ; then
    install_external
    install_openstack
else
    install_all
fi

# Information on what has been installed
puppet module list
