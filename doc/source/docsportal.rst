:title: Documentation Portal

Documentation Portal
####################

Documentation portal is a web server that serves documentation and
releasenotes created by various software projects of the Open Telekom Cloud.

At a Glance
===========

:Hosts:
  * https://docs.otc-service.com
:Projects:
  * https://github.com/opentelekomcloud-infra/docsportal
  * https://github.com/opentelekomcloud/otcdocstheme
:Configuration:
  * :git_file:`playbooks/roles/document_hosting_k8s/templates/nginx-site.conf.j2`
  * :git_file:`inventory/service/group_vars/k8s-controller.yaml`
:Bugs:
:Resources:

Overview
========

Every project managed by the Zuul Eco tenant is capable to use general jobs for
publishing documentation and releasenotes. Those jobs push rendered html
content into the Swift (dedicated containers) and make them word readable.

Software Architecture
=====================

A Web-Server (nginx) is listening in the frontend for the requests and based on
the URL decides in which container the data is actually located. It contacts
Swift as a backend server and gets the content from there. The content is then
being cached and returned back to the requestor.


Security Design
===============

Security Architecture
---------------------

Separation
----------

The project is not dealing with any kind of sensitive information. Due to that
it is deployed together with other Ecosystem managed components.

Interface Description
---------------------

The only public facing interface is the regular Web using HTTPS (automatic
forwarding from HTTP).

Tenant Security
---------------

Service is deployed in the Domain dedicated for the Ecosystem Squad. Only
members are having permissions there.

O&M Access Control
------------------

Only users enabled in the :git_file:`inventory/base/group_vars/all.yaml` are
able to login to the underlaying infrastructure.


Logging and Monitoring
----------------------

There are 2 sets of logs available:

* haproxy logs (on the proxyX.YY VMs)
* nginx log (Kubernetes POD log)


Patch Management
----------------

The service consists of OpenSource elements only. Whenever new release of any
software element (haproxy, nginx) is identified a Pull Request to this
repository need to be created to use it in the deployment.
Pathing of the underlaying VM (haproxy) is executed as a regular job applying
all the existing OS updates.

Hardening
---------

All configuration files for the hosts, Cloud Load Balancer configuration and K8
configuration is part of this repository. Every VM is managed by the System
Config project applying the same hardening rules to evenry host according to
the configuration

* :git_file:`inventory/service/host_vars/proxy1.eco.tsi-dev.otc-service.com.yaml`
* :git_file:`inventory/service/host_vars/proxy2.eco.tsi-dev.otc-service.com.yaml`

Certificate Handling
--------------------

SSL Certificates are obtained using Let's Encrypt Certificate authority
(:git_file:`playbooks/acme-certs.yaml`).
Following is important:

* Certificate for the K8 deployment is created and validated on the bride host.
* Service deployment procedure (:git_file:`playbooks/service-docs.yaml`)
  manages certificate secret in the Kubernetes.
* Haproxy certificates are generated using the same procedure on the haproxy
  hosts themselves.
* Certificate renewal and service reload happens automatically.

Backup and Restore
------------------

No backup/restore procedure exists besides Swift backup/restore. In general
regenration of the documentation is required in the case of data loss or
complete reprovisioning.


User and Account management
---------------------------

No user accounts on the documentation portal are existing. Only a regular
anonym access to the service is possible.

Communication Matrix
--------------------

.. list-table::

   * - From/To
     - Swift
     - K8
     - haproxy
     - elb
   * - Swift
     - N/A
     - HTTPS
     - N/A
     - N/A
   * - K8
     - HTTPS
     - N/A
     - HTTPS
     - N/A
   * - haproxy
     - N/A
     - HTTPS
     - N/A
     - TCP(443)
   * - elb
     - N/A
     - N/A
     - TCP(443)
     - N/A


Deployment
==========

* ``playbooks/service-docs.yaml`` is a playbook for the service configuration
  and deployment.
