:title: Git Control

Git Control
###########

Automation of the GitHub Organizations management.

At a Glance
===========

:Hosts:
:Projects:
  * https://github.com/opentelekomcloud/ansible-collection-gitcontrol
  * `Gitstyring`_
:Configuration:
    * https://github.com/opentelekomcloud-infra/gitstyring/tree/main/orgs
    * supplementary closed source project (gitlab/ecosystem/gitstyring)
:Bugs:
:Resources:

Overview
========

This project combination is taking care of automating management of the Open Telekom Cloud GitHub organizations. It currently takes care of following:

* project settings in the organizations
* branch protection for the projects
* team/collaborator permissions on the projects
* organization team management (description, membership)
* organization collaborator management (membership)

Software Architecture
=====================

Ansible collection (`opentelekomcloud.gitcontrol`) is implementing modules for the managing GitHub organizations, projects, users. `Gitstyring`_ project defines the configuration to be applied.

Security Design
===============


Security Architecture
---------------------

Managing GitHub object requires a OAuth token with admin privileges. This token is being kept in a secret inventory which is available to the :ref:`bridge` host. Ansible playbook (invoking finally the REST API of the GitHub) is then using this token.

Separation
----------

Not applicable

Interface Description
---------------------

Not available

Tenant Security
---------------

Not applicable

O&M Access Control
------------------

Only users enabled in the :git_file:`inventory/base/group_vars/all.yaml` are
able to login to the underlaying infrastructure.

Logging and Monitoring
----------------------

Logs for the execution can be found on the :ref:`bridge` host.

O&M Access Control
------------------

Only users enabled in the :git_file:`inventory/base/group_vars/all.yaml` are
able to login to the underlaying infrastructure.

Logging and Monitoring
----------------------

Logs are available on the :ref:`bridge` host.

Patch Management
----------------

This is not a real service not requiring any standalone system.

Hardening
---------

Not applicable.

Certificate Handling
--------------------

Not required.

Backup and Restore
------------------

Not applicable.

User and Account management
---------------------------

User mapping is configured by `Gitstyring`_. No password/token management is implemented.

In order to address data privacy concerns overall configuration data is split between 2 repositories:

- public one (https://github.com/opentelekomcloud-infra/gitstyring/) with the project configuration
- private one with the users and teams configuration

Communication Matrix
--------------------

Not applicable.

Deployment
==========

* :git_file:`playbooks/manage-github.yaml` is a playbook for the service configuration
* Zuul job ``infra-prod-manage-github`` is executed periodically and upon merged changes in the `Gitstyring`_ project got merged.

.. _Gitstyring: https://github.com/opentelekomcloud-infra/gitstyring
