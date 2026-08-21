# Node image for jobs whose payload deploys systemd units.
#
# cloudmon's ansible roles write 15 *.service unit templates and run 68 systemd
# tasks, so the node needs a real init. systemd has to be PID 1, which cannot be
# arranged after the container has started -- hence a dedicated image rather
# than installing systemd from the job.
#
# Requires, at the pod level: privileged, /sys/fs/cgroup mounted (the cluster is
# cgroup v1), and tmpfs on /run.
FROM quay.io/opentelekomcloud/python-tox:latest

# Base image runs as "zuul"; apt and PID 1 both need root, and the pod spec
# already sets runAsUser 0.
USER root

ENV DEBIAN_FRONTEND=noninteractive \
    container=docker

RUN sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
       systemd \
       systemd-sysv \
       dbus \
       cron \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Units that assume real hardware or a real boot hang or fail in a container.
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
          /etc/systemd/system/*.wants/* \
          /lib/systemd/system/local-fs.target.wants/* \
          /lib/systemd/system/sockets.target.wants/*udev* \
          /lib/systemd/system/sockets.target.wants/*initctl* \
          /lib/systemd/system/basic.target.wants/* \
          /lib/systemd/system/anaconda.target.wants/* \
  && rm -f /lib/systemd/system/systemd-firstboot.service \
           /lib/systemd/system/systemd-machine-id-commit.service \
  && systemctl set-default multi-user.target

VOLUME [ "/sys/fs/cgroup" ]

# systemd expects SIGRTMIN+3 to shut down cleanly.
STOPSIGNAL SIGRTMIN+3

CMD ["/lib/systemd/systemd"]
