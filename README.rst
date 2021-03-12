OpenTelekomCloud System Configuration
=====================================

This is the machinery that drives the configuration, testing,
continuous integration and deployment of services provided by the
OpenTelekomCloud project. It is heavily copies OpenDev configuration
approach.

Services are driven by Ansible playbooks and associated roles stored
here.  If you are interested in the configuration of a particular
service, starting at ``playbooks/service-<name>.yaml`` will show you
how it is configured.

Most services are deployed via containers; many of them are built or
customised in this repository; see ``docker/``.

A small number of legacy services are still configured with Puppet.
Although the act of running puppet on these hosts is managed by
Ansible, the actual core of their orchestration lives in ``manifests``
and ``modules``.
