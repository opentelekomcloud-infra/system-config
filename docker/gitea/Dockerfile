# Gitea Docker Hardened Image plus the shell utilities the upstream Helm
# chart needs.
#
# The chart mounts config_environment.sh at /usr/sbinx and runs it in the
# init-app-ini container to generate app.ini. That script shells out to awk
# (lines 18, 57, 94), find (105), grep (126) and xargs, unconditionally --
# it is core config generation, not an optional feature, so it cannot be
# switched off through values. The hardened base ships bash but none of
# those, so without this layer the init container dies with
# "/usr/sbinx/config_environment.sh: line 126: grep: command not found".
#
# busybox provides all four from a single statically linked binary, which
# keeps the added surface to one file.

FROM docker.io/library/busybox:1.37.0-musl AS busybox

FROM swr.eu-de.otc.t-systems.com/t-cloud-public/gitea:1.27.2-rootless

LABEL maintainer="Ecosystem squad - DL-PBCOTCDELECO@t-systems.com"

USER root

COPY --from=busybox /bin/busybox /usr/local/bin/busybox

# ln comes from busybox itself; the hardened base has no coreutils.
RUN /usr/local/bin/busybox ln -s busybox /usr/local/bin/awk && \
    /usr/local/bin/busybox ln -s busybox /usr/local/bin/find && \
    /usr/local/bin/busybox ln -s busybox /usr/local/bin/grep && \
    /usr/local/bin/busybox ln -s busybox /usr/local/bin/xargs

USER 1000
