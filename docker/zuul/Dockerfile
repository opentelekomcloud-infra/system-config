# Copyright (c) 2019 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
FROM docker.io/opendevorg/python-builder:3.10-bullseye as base
RUN apt-get update \
  && apt-get install -y git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN  git config --global user.email "zuul@otc-service.com" && \
     git config --global user.name "SystemConfig"

RUN git clone https://opendev.org/zuul/zuul zuul_src && \
    cd /zuul_src && \
    git pull https://review.opendev.org/zuul/zuul refs/changes/08/850008/2

FROM docker.io/library/node:16-bullseye as js-builder

COPY --from=base /zuul_src/web /tmp/src
# Explicitly run the Javascript build
RUN cd /tmp/src && yarn install -d && yarn build

FROM docker.io/opendevorg/python-builder:3.10-bullseye as builder
ENV DEBIAN_FRONTEND=noninteractive

# Optional location of Zuul API endpoint.
ARG REACT_APP_ZUUL_API
# Optional flag to enable React Service Worker. (set to true to enable)
ARG REACT_APP_ENABLE_SERVICE_WORKER
# Kubectl/Openshift version/sha
ARG OPENSHIFT_URL=https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
ARG OPENSHIFT_SHA=4b0f07428ba854174c58d2e38287e5402964c9a9355f6c359d1242efd0990da3

COPY --from=base /zuul_src /tmp/src
COPY --from=js-builder /tmp/src/build /tmp/src/zuul/web/static
RUN assemble

# The wheel install method doesn't run the setup hooks as the source based
# installations do so we have to call zuul-manage-ansible here. Remove
# /root/.local/share/virtualenv after because it adds wheels into /root
# that we don't need after the install step so are a waste of space.
RUN /output/install-from-bindep \
  && zuul-manage-ansible \
  && rm -rf /root/.local/share/virtualenv \
# Install openshift
  && mkdir /tmp/openshift-install \
  && curl -L $OPENSHIFT_URL -o /tmp/openshift-install/openshift-client.tgz \
  && cd /tmp/openshift-install/ \
  && echo $OPENSHIFT_SHA /tmp/openshift-install/openshift-client.tgz | sha256sum --check \
  && tar xvfz openshift-client.tgz --strip-components=1 -C /tmp/openshift-install

FROM docker.io/opendevorg/python-base:3.10-bullseye as zuul
ENV DEBIAN_FRONTEND=noninteractive

COPY --from=builder /output/ /output
RUN /output/install-from-bindep zuul_base \
  && rm -rf /output \
  && useradd -u 10001 -m -d /var/lib/zuul -c "Zuul Daemon" zuul \
# This enables git protocol v2 which is more efficient at negotiating
# refs.  This can be removed after the images are built with git 2.26
# where it becomes the default.
  && git config --system protocol.version 2

VOLUME /var/lib/zuul
CMD ["/usr/local/bin/zuul"]

FROM zuul as zuul-executor
ENV DEBIAN_FRONTEND=noninteractive
ENV ANSIBLE_5_EXTRA_PACKAGES=hvac
COPY --from=builder /usr/local/lib/zuul/ /usr/local/lib/zuul
COPY --from=builder /tmp/openshift-install/kubectl /usr/local/bin/kubectl
COPY --from=builder /tmp/openshift-install/oc /usr/local/bin/oc

RUN apt-get update \
  && apt-get install -y skopeo \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN /usr/local/bin/zuul-manage-ansible

CMD ["/usr/local/bin/zuul-executor", "-f"]

FROM zuul as zuul-fingergw
CMD ["/usr/local/bin/zuul-fingergw", "-f"]

FROM zuul as zuul-merger
CMD ["/usr/local/bin/zuul-merger", "-f"]

FROM zuul as zuul-scheduler
CMD ["/usr/local/bin/zuul-scheduler", "-f"]

FROM zuul as zuul-web
CMD ["/usr/local/bin/zuul-web", "-f"]
