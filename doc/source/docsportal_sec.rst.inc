Security Design
===============

.. graphviz:: dot/docsportal_sec.dot
   :caption: Docs portal secutiry architecture

Security Architecture
---------------------

Documentation portal takes care of making documentation publicly available.
This means that the content it is processing will be publicly available. No
care about avoiding placing sensitive information from git repositories is
taken and it is explicitly in the responsibility of each individual project
maintainers to ensure no sensitive information land in git.

Ensuring, that only checked and approved content will be merged in git and
published is a primary responsibility of :ref:`Zuul` which applies also
:ref:`git_control` to manage required conditions that need to be fulfilled on
every pull request of every project.

Separation
----------

The project is implemented as a combination of multiple software
and solution components communicating with each other. Those
components are installed physically separated from each other
with no direct connectivity except of public HTTPS.

* Web Server

  * Nginx web server accepts HTTP protocol requests. It rewrites
    the request to a destination on the Remote Storage.

  * It performs remote request to fetch the requested content
    and serves it back to the initial requestor.

  * Depending on the content accessibility web server is either exposed
    directly to the web or behind additional reverse proxy implementing 
    required security limitations.

* Storage

  * OpenStack Swift storage. Practically this can be any other object storage
    which allows web access.

  * Zuul CI/CD writes approved content into the storage
    destination.

  * Web Server fetches the content.

  * The content in the Storage for the Documentation Portal is by
    definition public content (not protected by any additional ACLs).

  * If the content is not designed to be publicly available content in the
    Storage must be protected by ACLs. This in turn will require enabling web
    server to access this content (i.e. swift-proxy in the case of using
    OpenStack Swift).

* :ref:`zuul`

  * Zuul installation manages git projects and implements
    configured CI rules in order to ensure that only checked and
    approved content will be merged. Default configuration
    forbids anybody (except of Zuul Administrators) to bypass
    required checks and merge content manually
  * Once all the prerequisites are fulfilled Zuul merges Pull
    Request, builds documentation and pushes it to storage with
    dedicated credentials.
  * Only git projects explicitly included in the Zuul tenant are
    being respected. Registered git projects with disabled
    branch protection rules are ignored.

* `GitHub <https://github.com>`_

  * An external git hosting provider.
  * Projects in the GitHub organization are managed by `dedicate process
    <https://docs.otc-service.com/system-config/gitcontrol.html>`_

Interface Description
---------------------

The only public facing interface is the regular Web using HTTPS (automatic
forwarding from HTTP).

Tenant Security
---------------

Documentation Portal is not providing any tenant support. All documents that are hosted
on the Help Center are placed in a dedicated storage (as public content). User
management is also not supported.

O&M Access Control
------------------

Only users enabled in the :git_file:`inventory/base/group_vars/all.yaml` are
able to login to the underlaying infrastructure. Direct access to the hosts is
only possible through the :ref:`Bridge` host which serves as a bastion host.

Logging and Monitoring
----------------------

Every component of the HelpCenter produces own logs.

* haproxy log (VM service logs)
* nginx log (VM or Kubernetes POD log)
* Swift proxy and storage service logs
* Zuul logs

  * public job logs (test build log file)
  * executor log
  * scheduler log

Patch Management
----------------

The service consists of OpenSource elements only. Whenever new release of any
software element (haproxy, nginx, zuul) is identified a Pull Request to this
repository need to be created to update the software. Pathing of the
underlaying VM (haproxy) is executed as a regular job applying all the existing
OS updates.

Hardening
---------

All configuration files for the hosts, Cloud Load Balancer configuration and K8
configuration is part of this repository. Every VM is managed by the System
Config project applying the same hardening rules to evenry host according to
the configuration.

Web server is deployed as a Kubernetes pod in a dedicated namespace and receives an Ingress.

Certificate Handling
--------------------

SSL Certificates are obtained using Let's Encrypt Certificate authority.
Following is important:

* Certificate for the K8 deployment can managed by the
  `CertManager <https://cert-manager.io/>`_ deployed in
  the Kubernetes cluster. This is achieved by placing
  Kubernetes annotation on the deployment.
* Alternatively SSL Certificate for the K8 installation may be generated on the
  deployment server and provided into the K8 as secrets.
* Certificates for the other involved components (Zuul,
  Swift) are managed by the corresponding components
  themselves.

Backup and Restore
------------------

No backup/restore procedure exists besides Swift backup/restore. In general
the best approach is a regeneration of the documentation. This is also used
when i.e. applying updated styling is required on all documents without
triggering changes in each project independently.

User and Account management
---------------------------

No user accounts on the documentation portal are existing. Only a regular
anonym access to the service is possible. No cookies or local web browser storage is used.

Communication Matrix (external)
-------------------------------

Complete communication between Help Center elements is happening as with
external components (using HTTPS). 

Depending on the requirements additional reverse proxy may be installed in from
of the web server to provide additional hardening or other required isolation
measures. Also in this case communication between reverse proxy and the web
server is happening as HTTPS traffic.

.. list-table::

   * - From/To
     - Web Server
     - Storage
     - Zuul
     - GitHub
   * - WebServer
     - N/A
     - HTTPS
     - N/A
     - N/A
   * - Storage
     - N/A
     - N/A
     - N/A
     - N/A
   * - Zuul
     - N/A
     - HTTPS
     - N/A
     - HTTPS
   * - GitHub
     - N/A
     - N/A
     - HTTPS
     - N/A
