An ansible role to install docker in the OpenStack infra production environment

This also installs a log redirector for syslog ```docker-`` tags.  For
most containers, they can be setup in the compose file with a section
such as:

.. code-block:: yaml

   logging:
     driver: syslog
     options:
       tag: docker-<appname>

**Role Variables**

.. zuul:rolevar:: use_upstream_docker
   :default: True

   By default this role adds repositories to install docker from upstream
   docker. Set this to False to use the docker that comes with the distro.

.. zuul:rolevar:: docker_update_channel
   :default: stable

   Which update channel to use for upstream docker. The two choices are
   ``stable``, which is the default and updates quarterly, and ``edge``
   which updates monthly.
