OpenTelekomCloud System Configuration
=====================================

This is the machinery that drives the configuration, testing, continuous
integration and deployment of services provided by the OpenTelekomCloud
project. It heavily copies OpenDev configuration approach with some extensions
and deviations.

Services are driven by Ansible playbooks and associated roles stored here. If
you are interested in the configuration of a particular service, starting at
``playbooks/service-<name>.yaml`` will show you how it is configured.

Most services are deployed via containers; many of them are built or customised
in this repository; see `docker/`.
