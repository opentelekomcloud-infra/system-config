:title: Proxy

Reverse Proxy
#############

Multiple resources are deployed behind the reverse proxy in order to enable
proper load balancing, failover and hybrid resource deployment (resources
deployed in different networks without possibility to use Cloud Load Balancer).

At a Glance
===========

:Hosts:
:Projects:
  * https://www.haproxy.org/
:Configuration:
  * :git_file:`inventory/service/group_vars/proxy.yaml`
  * :git_file:`playbooks/roles/haproxy/templates/haproxy.cfg.j2`
:Bugs:
:Resources:

Software Architecture
=====================

A regular unmodified haproxy software is deployed in VMs and is exposed through
the Cloud Load Balancer.

Security Design
===============

Security Architecture
---------------------

* haproxy is deployed in a container on a dedicated VM
* firewalld component is deployed on the VM and is only opening required ports
  (configured part of this repository)
* VMs are not having public IP and can be only physically accessed through
  :ref:`bridge`
* HTTP/HTTPS traffic is reaching the service through Cloud Load Balancer

Separation
----------

Service runs on the dedicated VMs without any other additional service running.

Interface Description
---------------------

Cloud load balancer is distributing load across mutiple haproxy instances. It
exposes ports 80 and 443 in the internal network, where those are consumed by
the Cloud Load Balancer.

Tenant Security
---------------

No customer Service is deployed in the Domain dedicated for the Ecosystem Squad. Only
members are having permissions there.

O&M Access Control
------------------

Only users enabled in the :git_file:`inventory/base/group_vars/all.yaml` are
able to login to the underlaying infrastructure.

Logging and Monitoring
----------------------

* haproxy logs (on the proxyX.YY VMs)
* haproxy emits StatsD metrics into the Graphite DB and those can be observed
  using Grafana


Patch Management
----------------

The service consists of OpenSource elements only. Whenever new release of any
software element (haproxy) is identified a Pull Request to this
repository need to be created to use it in the deployment.
Pathing of the underlaying VM (haproxy) is executed as a regular job applying
all the existing OS updates.

Hardening
---------

All configuration files for the hosts part of this repository. Every VM is managed by the System
Config project applying the same hardening rules to every host according to
the configuration

* :git_file:`inventory/service/host_vars/proxy1.eco.tsi-dev.otc-service.com.yaml`
* :git_file:`inventory/service/host_vars/proxy2.eco.tsi-dev.otc-service.com.yaml`

Certificate Handling
--------------------

SSL Certificates are obtained using Let's Encrypt Certificate authority
(:git_file:`playbooks/acme-certs.yaml`).
Following is important:

* Haproxy certificates are generated using the same procedure on the haproxy
  hosts themselves.
* Certificate renewal and service reload happens automatically.

Backup and Restore
------------------

No backup/restore procedure exists. Infrastructure deployment is automated and
can be redeployed when necessary.


User and Account management
---------------------------

No user accounts are existing.

Communication Matrix
--------------------

.. list-table::

   * - From \\ To
     - haproxy
     - elb
   * - haproxy
     - N/A
     - N/A
   * - elb
     - TCP(80,443)
     - N/A


Deployment
==========

* ``playbooks/service-proxy.yaml`` is a playbook for the service configuration
  and deployment.
