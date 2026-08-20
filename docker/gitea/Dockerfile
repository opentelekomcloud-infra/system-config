# Gitea Docker Hardened Image plus the shell utilities the upstream Helm
# chart needs.
#
# The chart's init containers run scripts that shell out to utilities the
# hardened base does not ship, and none of it can be switched off through
# values -- it is core startup logic:
#   config_environment.sh (init-app-ini)  awk, find, grep, xargs
#     generates app.ini; without grep it dies at line 126 with
#     "config_environment.sh: line 126: grep: command not found"
#   configure_gitea.sh (configure-gitea)  nc
#     waits for valkey; without it, "Valkey not reachable after 30 attempts"
#
# The list was derived by testing the base image against every command the
# rendered chart invokes, not by reading the scripts -- an env-var prefix
# ("RES_OPTIONS=... nc -vz") hides calls from a naive grep. sed is the only
# other utility the chart family commonly uses that the base lacks, so it
# is included to avoid a third round of this.
#
# busybox provides all of them from one statically linked binary, keeping
# the added surface to a single file.

FROM docker.io/library/busybox:1.37.0-musl AS busybox

FROM swr.eu-de.otc.t-systems.com/t-cloud-public/gitea:1.27.2-rootless

LABEL maintainer="Ecosystem squad - DL-PBCOTCDELECO@t-systems.com"

USER root

COPY --from=busybox /bin/busybox /usr/local/bin/busybox

# ln comes from busybox itself; the hardened base has no coreutils.
RUN for c in awk find grep nc sed xargs; do \
      /usr/local/bin/busybox ln -s busybox "/usr/local/bin/$c"; \
    done

USER 1000

USER 1000
