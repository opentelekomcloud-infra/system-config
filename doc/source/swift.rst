:title: Swift

OpenStack Swift
###############

Open Telekom Cloud Swift is not matching the OpenStack software. As an attempt
to overcome compatibility issues a real upstream software can be used with no
code changes.

At a Glance
===========

:Hosts:
  * https://swift.eco.tsi-dev.otc-service.com
:Projects:
  * https://opendev.org/openstack/swift
  * https://github.com/opentelekomcloud-infra/validatetoken
:Configuration:
:Bugs:
:Resources:
 * `OpenStack Swift documentation`_

Overview
========

Upstream OpenStack Swift software is deployed in an isolated Open Telekom Cloud
project and is exposed using the Cloud Load Balancer.


Software Architecture
=====================

Software components
-------------------

* OpenStack Swift Proxy service - Authorization and API handling
* OpenStack Swift Storage services - Data storage
* Keystone authentication middleware (validatetoken) - oslo middleware to
  verify token information

Network setup
-------------

* external network (API handling)
* storage network (communication between proxy services and storage nodes)
* replication network (data synchronization between storage nodes)
* management network (used to provision software)
* cloud load balancer is using the external network to communicate with Swift
  proxy servers

Security Design
===============

Swift is not having any authentication database. In order to verify validity of
the API request it sends API request to the Keystone (IAM) for the verification
of the passed token. When the positive information is received Swift decides
further on whether the user is authorized to do the action. This is happening
based on the roles the user has and does not require any additional (local)
information.

Software is deployed in an isolated Project of the Open Telekom Cloud public Domain and does not share the infrastructure with any other components. Management of the installation is achieved using the vpc peering between management network of the installation and the :ref:`bridge`.

User data is stored on the Storage nodes not encrypted. Technically it is
possible to enable `encryption <https://docs.openstack.org/swift/pike/overview_encryption.html>`_, but due to
the absense of any customer or in any other way sensitive data it is not
enabled.

Separation
----------

* Software is deployed in an isolated project
* Hosts to run the software has multiple networking interfaces and only
  required traffic is allowed to run (default - drop)

Interface Descritpion
---------------------

Service is exposed to the internet only through the load balancer HTTPS port.
This implements `REST API <https://docs.openstack.org/api-ref/object-store/>`.
Authorization requires passing `X-Auth-Token` header with a valid Identity
token.

Tenant Security
---------------

An isolated project and isolated management user is used.

O&M Access Control
------------------

Only users enabled in the :git_file:`inventory/base/group_vars/all.yaml` are
able to login to the underlaying infrastructure.


Logging and Monitoring
----------------------

There are 2 sets of logs available:

* proxy logs (on the proxy VMs)
* account/container/object service log (on the storage VMs)

Certificate Handling
--------------------

SSL Certificates are obtained using Let's Encrypt Certificate authority
(:git_file:`playbooks/acme-certs.yaml`). Certificate for Swift is generated on
the :ref:`bridge` host and is uploaded to the Cloud Load Balancer service after
rotation.

Backup and Restore
------------------

No Backup and Restore functionality is currently implemented.

User and Account management
---------------------------

Official Open Telekon Cloud Identity Service (IAM) is used for user and account
management. No related data is stored in Swift.

Communication Matrix
--------------------

.. list-table:: External communication matrix

   * - From/To
     - Swift
     - elb
   * - Swift
     - N/A
     - N/A
   * - elb
     - HTTP(8080)
     - N/A


.. list-table:: Internal communication matrix

   * - From/To
     - bridge
     - proxy
     - storage
   * - bridge
     - SSH
     - SSH
     - SSH
   * - proxy
     - N/A
     - N/A
     - TCP(6200,6201,6202)
   * - storage
     - N/A
     - N/A
     - Rsync

Deployment
==========


.. _OpenStack Swift Documentation: https://docs.openstack.org/swift/latest/overview_architecture.html
