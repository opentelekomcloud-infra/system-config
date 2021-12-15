:title: Zuul CI/CD

.. _Zuul: https://zuul-ci.org/docs/zuul

Zuul CI/CD
##########

Zuul is a pipeline-oriented project gating system. It facilitates
running tests and automated tasks in response to Code Review events.

At a Glance
===========

:Hosts:
  * https://zuul.otc-service.com
:Projects:
  * https://opendev.org/zuul/zuul
:Configuration:
  * :git_file:`inventory/service/group_vars/zuul.yaml`
:Bugs:
:Resources:
  * `Zuul Reference Manual`_
:Chat:
  * #zuul:matrix.otc-service.com Matrix room

Overview
========

The Open Telekom Cloud project uses a number of pipelines in Zuul:

**check**
  Newly uploaded patchsets enter this pipeline to receive an initial
  +/-1 Verified vote.

**gate**
  Changes that have been approved by core reviewers are enqueued in
  order in this pipeline, and if they pass tests, will be merged.

**post**
  This pipeline runs jobs that operate after each change is merged.

**release**
  When a commit is tagged as a release, this pipeline runs jobs that
  publish archives and documentation.

**tag**
  When a commit is tagged as a release (non semantic naming scheme), this
  pipeline runs jobs that publish archives and documentation.

**periodic**
  This pipeline has jobs triggered on a timer for e.g. testing for
  environmental changes daily.

**promote**
   This pipeline runs jobs that operate after each change is merged
   in order to promote artifacts generated in the gate
   pipeline.

The **gate** pipeline uses speculative execution to improve
throughput.  Changes are tested in parallel under the assumption that
changes ahead in the queue will merge.  If they do not, Zuul will
abort and restart tests without the affected changes.  This means that
many changes may be tested in parallel while continuing to assure that
each commit is correctly tested.

Zuul's current status may be viewed at
`<https://zuul.otc-service.com>`_.

Software Architecture
=====================

Please refer to `zuul`_ documentation for detailed explanation on how Zuul is designed.

.. raw:: html

   <object data="_static/zuul.svg" type="image/svg+xml"></object>

Security Design
---------------

Security Architecture
~~~~~~~~~~~~~~~~~~~~~

.. raw:: html

   <object data="_static/zuul_sec.svg" type="image/svg+xml"></object>

Separation
~~~~~~~~~~

Zuul consists of the following major components:

* nodepool-launcher
* nodepool-builder
* zuul-executor
* zuul-scheduler
* zuul-merger
* zuul-web

In addition to the components of Zuul itself following external components
are used:

* zookeeper
* SQL database
* cloud resources (for spinning VMs or containers for job executions)

None of the components of Zuul are communicating directly with each other and
instead rely on external Zookeeper with TLS encryption for exchanging
information. Components are using TLS certificates to authorize to Zookeeper.

Details can be found at `Zuul Components`_.

Interface Description
~~~~~~~~~~~~~~~~~~~~~

Zuul system is implementing following interfaces for the communication with
the outside systems:

* Web component (managed by zuul-web component):

  * Web UI interface (gives user information on job status)
  * REST API (allows R/O operations for querying status)
  * Webhook listener (listens for events from git hosting backends)

In addition to that Zuul accesses following systems:

* Zookeeper (for internal communication)

  * protected with TLS and TLS client certificates

* SQL Database (for storing job results)

  * protected with TLS and username/password

* External Log Storage (Swift for storing job logs)

  * protected with TLS and username/password/token

* Git hosting (for read and write operations)

  * Relies on the SSH access protected with SSH key

* Cloud resources (for performing required test)

  * protected according to the requirements of the particular cloud provider
    (username/password, token, client certificate). In general TLS is used for
    API invocation (for provisioning resources) and afterwards SSH with private
    key to further execute Ansible on the resource. Once the resource is not 
    used anymore, API request is sent to the cloud provider via TLS to decommission it.

Further details can be found `Zuul Admin Reference`_.

Tenant Security
~~~~~~~~~~~~~~~

Every tenant of Zuul is configured through the `zuul-config`_ repository.
Every tenant includes list of projects which are allowed to use system. Git
projects not configured are ignored. In addition to that only events from git
projects with enabled branch protections are respected by Zuul.

During job execution by `zuul-executor
<https://zuul-ci.org/docs/zuul/discussion/components.html#executor>`_
projects are being tested in a completely isolated context guaranteeing both
isolation of projects as well as protection of the system from potential
vulnerabilities or malicious actions by the projects themselves).

Zuul jobs triggered upon corresponding git actions are executed either in
isolated dedicated VMs provisioned in the cloud or in Kubernetes pods in
isolated namespaces.

Further details can be found `Zuul Tenant Configuration`_.

O&M Access Control
~~~~~~~~~~~~~~~~~~

Zuul administrators are having access to any component of the Zuul system.
This gives possibility to access execution logs of test jobs (which are
anyway published at the end of the excution), as well as enqueue/dequeue
particular pipelines for the project pull/merge request. This access,
however, does not give any possibility to bypass project set requirements on
code merging (Zuul administrator is not able to enforce pull/merge request
merging), this can be done only by people with direct git hosting admin or
write access.

Logging and Monitoring
~~~~~~~~~~~~~~~~~~~~~~

Zuul is logging all jobs being performed. This information is made public so
that pull request initiators are able to know status of the test. It must be
noted, however, that every Zuul tenant is reponsible for defining base jobs
which are either making logs publicly available or not. In general those jobs
are themselves responsible for maintaining the log files (whether to put them
on some external log hosting or discard them immediately).

Zuul internal logging is done completely independently and is produced on the systems running Zuul components themselves. These logs are maintained corresponsing to the requirements of the Zuul installation.

In addition to the Zuul components logging, it also supports metric emitting. It supports StatsD metrics pushing and Prometheus metric fetching. More details `Zuul Monitoring`_.

Patch Management
~~~~~~~~~~~~~~~

Zuul administrators are responsible for updating Zuul software and taking care of the platform where those components are running.

Hardening
~~~~~~~~~

As a means of hardening of the Zuul installation following can be mentioned:

* Zuul is deployed in a dedicated Kubernetes cluster and every component is
  running as a container.

* Access to the Zuul UI and REST API is implemented through the Cloud Load
  Balancer and K8 Ingress controller attached to it

* Secret data used in Zuul is stored in Vault and can be easily rotated with
  required frequency.

* Cloud resources used by Zuul are protected by security groups. Moreover
  connection is implemented by the means of internal VPC peering connections
  with no direct access using public IP addresses.

* Zookeeper instance used by Zuul is a dedicated instance with no external access.

* SQL DB used by Zuul is a dedicated instance with no public IP address.

* API and SSH access to git hosting can be additionally protected by the
  whitelisting of Zuul external IP address.

Backup and Restore
~~~~~~~~~~~~~~~~~~

Zuul is build on the principles of storing all required information in git.
This is applicable for the configuration of which jobs are executed for which
project, as well as what is the Zuul configuration. This makes Backup more or
less obsolete. Of course there are some parts of the installation that
require backups:

* private/public keys for the project secrets (private keys are in addition protected by password).

Details on the methods can be found `here <https://zuul-ci.org/docs/zuul/reference/client.html>`_.

Certificate Handling
~~~~~~~~~~~~~~~~~~~~~

There are few types of certificates used in Zuul:

* Zookeeper client TLS certificates
* TLS certificates for the API/UI (Web access)
* API keys and private certificates for SSH and API access to git hoster.

Those certificates must be maintained according to the security
requirements and deployment specifics. In general it is preferred to use
short-lived self-signed certificates for the Zookeeper cluster as well as
LetsEncrypt certificates for Web access.

User and account Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Generally Zuul does not support user accounts. It mainly communicates with
git hosting systems with appropriate credentials and has no information about
particular users proposing changes there.

Zuul supports optional `Tenant Scoped REST API
<https://zuul-ci.org/docs/zuul/discussion/tenant-scoped-rest-api.html>`_, but
this is currently not enabled in the current installation.

Operational accounts
^^^^^^^^^^^^^^^^^^^^

There are not granular operator accounts in Zuul installation. There is only one account allowing operate the system.

Technical and M2M accounts
^^^^^^^^^^^^^^^^^^^^^^^^^^

Every component of Zuul only communicates to Zookeeper. For this Zookeeper
client TLS certificate is used. No other technical or M2M accounts exist on
the system.

Communication Matrix (internal)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

As mentioned above Zuul components communicate with each other only through
Zookeeper. In order to keep communication simple those missing connections are
not mentioned explicitly.

.. list-table::

   * - From \\ To
     - zookeeper
     - vault
   * - nodepool-builder
     - TLS(2281)
     - TLS(8200)
   * - nodepool-launcher
     - TLS(2281)
     - TLS(8200)
   * - zuul-web
     - TLS(2281)
     - TLS(8200)
   * - zuul-merger
     - TLS(2281)
     - TLS(8200)
   * - zuul-executor
     - TLS(2281)
     - TLS(8200)
   * - zuul-scheduler
     - TLS(2281)
     - TLS(8200)
   * - zookeeper
     - TLS(2888,3888)
     - TLS(8200)

Zookeeper protocol details can be found at `Zookeeper Internals <https://zookeeper.apache.org/doc/r3.6.0/zookeeperInternals.html>`_.

Communication Matrix (external)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::

   * - From \\ To
     - SQL DB
     - Git hosting
     - Cloud
   * - nodepool-builder
     - N/A
     - N/A
     - [CLOUD_TLS]_
   * - nodepool-launcher
     - N/A
     - N/A
     - [CLOUD_TLS]_
   * - zuul-web
     - [DB_TLS]_
     - [TLS]_
     - N/A
   * - zuul-merger
     - N/A
     - [SSH]_
     - N/A
   * - zuul-executor
     - N/A
     - [SSH]_
     - [SSH]_
   * - zuul-scheduler
     - N/A
     - N/A
     - N/A

.. [TLS] HTTPS encrypted (TLS) on port 443
.. [SSH] SSH encrypted on custom port (depends on the git provider)
.. [CLOUD_TLS] HTTPS encrypted (TLS) on port 443
.. [DB_TLS] Database protocol, encrypted (TLS) (port depends on conrete DB type)

Deployment Design
=================

Zuul is installed in an isolated Kubernetes cluster. As a mean of further
security isolation SQL database and Zookeeper must be installaled dedicated
exclusively to the Zuul instance.

Secrets required for Zuul operation are fetched by the components from the
`Vault`_ instance. This is achieved by relying on the following items:

* https://www.vaultproject.io/docs/auth/kubernetes

  * Service account of the Zuul user is registered in the Vault for the
    corresponding K8 cluster and namespace.

* https://www.vaultproject.io/docs/secrets/kv/kv-v2

  * Strict policy is granted to the user giving read only access to the
    required secrets.

* https://www.vaultproject.io/docs/agent

  * Vault agent is deployed as a sidecar container for Zuul components which
    is reponsible for fetching required secrets from Vault and rendering them
    into the corresponding config files.

* Vault instance is not accessible publicly (has no public IP address)

.. raw:: html

   <object data="_static/zuul_dpl.svg" type="image/svg+xml"></object>

Network Deployment Design
-------------------------

Zuul components are installed inside of the single Kubernetes cluster. This
means all components are placed in dedicated virtual networks of the
Kubernetes. Communication with Zookeeper happens through the Kubernetes
Service.

Software Deployment Design
--------------------------

* nodepool-builder is deployed using
  :git_file:`playbooks/roles/zuul_k8s/tasks/nodepool.yaml`
* nodepool-launcher is deployed using
  :git_file:`playbooks/roles/zuul_k8s/tasks/nodepool.yaml`
* zuul-web component is deployed using
  :git_file:`playbooks/roles/zuul_k8s/tasks/zuul-web.yaml`
* zuul-merger component is deployed using
  :git_file:`playbooks/roles/zuul_k8s/tasks/zuul-merger.yaml`
* zuul-executor component is deployed using
  :git_file:`playbooks/roles/zuul_k8s/tasks/zuul-executor.yaml`
* zuul-scheduler component is deployed using
  :git_file:`playbooks/roles/zuul_k8s/tasks/zuul-scheduler.yaml`
* zookeeper is deployed using
  :git_file:`playbooks/roles/zookeeper/tasks/k8s.yaml`

.. _Zuul Reference Manual: https://zuul-ci.org/docs/zuul
.. _Zuul Status Page: http://zuul.otc-service.com
.. _zuul-config: https://github.com/opentelekomcloud-infra/zuul-config
.. _Zuul Admin Reference: https://zuul-ci.org/docs/zuul/reference/admin.html
.. _Zuul Tenant Configuration: https://zuul-ci.org/docs/zuul/reference/tenants.html
.. _Zuul Components: https://zuul-ci.org/docs/zuul/discussion/components.html
.. _Zuul Monitoring: https://zuul-ci.org/docs/zuul/reference/monitoring.html
.. _Vault: https://www.vaultproject.io/
