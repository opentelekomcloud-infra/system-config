:title: Git Control

Git Control
###########

Automation of the GitHub Organizations management.

At a Glance
===========

:Hosts:
:Projects:
  * `Ansible Collection Gitcontrol`_
  * `Gitstyring`_
:Configuration:
    * https://github.com/opentelekomcloud-infra/gitstyring/tree/main/orgs
    * supplementary closed source project (gitlab/ecosystem/gitstyring)
:Bugs:
:Resources:

Overview
========

This project combination is taking care of automating management of the Open
Telekom Cloud GitHub organizations. It currently takes care of following:

* project settings in the organizations
* branch protection for the projects
* team/collaborator permissions on the projects
* organization team management (description, membership)
* organization collaborator management (membership)

Software Architecture
=====================

Ansible collection (`opentelekomcloud.gitcontrol`) is implementing modules for
the managing GitHub organizations, projects, users. `Gitstyring`_ projects
defines the configuration to be applied.

:ref:`Zuul` jobs defined in the `Gitstyring`_ projects are responsible for
applying of the target configuration. The workflow is implemented as following:

- A temporary VM is prepared
- `Ansible Collection Gitcontrol`_ collection is installed together with Ansible
- Loop over target managed organizations:

  - Temporary GitHub token is retrieved according to `gh_auth`_ for the OTCBot
    GitHub application for the organization. Private key for token signing is
    retrieved from Vault.
  - Configured state of the organizaiton members is applied using temporary
    token.
  - Configured state of the organizaiton teams is applied using temporary
    token.
  - Configured state of the organizaiton projects is applied using temporary
    token.
  - Temporary token is revoked.

Security Design
===============


Security Architecture
---------------------

GitHub organizations are managed using OTCBot `GitHub application
<https://docs.github.com/en/developers/apps/building-github-apps>`_. This allows
avoiding necessity to use pre-created tokens with administration privileges.
Private key of the GitHub application is stored in the Vault and a special
Vault policy is defined to allow access to it. Required configuration projects
are using dedicated `AppRole <https://www.vaultproject.io/docs/auth/approle>`_
in combination with the mentioned policy to restrict which projects are able to
access the key. Using the application private key a JWT token is generated
which is used to get application installation token with the required scope to
be able to apply the configuration to the organization.
After using the installation token is forcibly revoked by sending DELETE call
to the GitHub API.

As a next step step for improving security a special Vault plugin is going to
be created that takes organization name and desired permission set and returns
dedicated installation token. this will allow avoiding private key to ever
leave Vault.

Every change proposed to the target configuration will be applied in the
dry-run mode using token with read-only privileges to verify configuration.

Separation
----------

Not applicable.

Interface Description
---------------------

Not available.

Tenant Security
---------------

Not applicable.

O&M Access Control
------------------

Not applicable.

Logging and Monitoring
----------------------

Logs for the execution can be found in the corresponding Zuul job execution
logs.

Patch Management
----------------

Not applicable.

Hardening
---------

Not applicable.

Certificate Handling
--------------------

Not required.

Private key of the GitHub application is kept in the Vault. It can be rotated
by generating new key by the administrators of the GitHub
opentelekomcloud-infra members and overwriting it in the Vault.

Backup and Restore
------------------

Not applicable.

User and Account management
---------------------------

User mapping is configured by `Gitstyring`_. No password/token management is implemented.

Communication Matrix
--------------------

Not applicable.

Deployment
==========

Not applicable.

.. _Gitstyring: https://github.com/opentelekomcloud-infra/gitstyring
.. _`Ansible Collection Gitcontrol`: https://github.com/opentelekomcloud/ansible-collection-gitcontrol
.. _gh_auth: https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps#authenticating-as-a-github-app>
