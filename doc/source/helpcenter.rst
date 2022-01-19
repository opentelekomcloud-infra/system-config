:title: Help Center

Help Center
###########

Open Telekom Cloud Help Center is a web server that serves documentation and
releasenotes created by various software projects of the Open Telekom Cloud.

At a Glance
===========

:Hosts:
  * https://docs-beta.otc.t-systems.com
:Projects:
  * https://github.com/opentelekomcloud/otcdocstheme
  * https://github.com/opentelekomcloud-docs/docsportal
  * https://github.com/opentelekomcloud-docs/
:Configuration:
  * :git_file:`playbooks/roles/document_hosting_k8s/templates/nginx-site.conf.j2`
  * :git_file:`inventory/service/group_vars/k8s-controller.yaml`
:Bugs:
:Resources:

Overview
========

Every project on the GitHub under the opentelekomcloud-docs organization is
capable in delivering documentation to the Help Center. Originally this
documentation represents API reference documents and User Guides which need to
be served on the Help Center for user reference. However there is no general
limitation on which type of documents are managed and projects can manage
further content (i.e. developer guides, how-tos, etc).

Every git project ideally represents a single service of the Open Telekom
Cloud.

Integration of projects under the :ref:`Zuul` allows following:

- CI for the changes in the project (i.e. only tested and approved content is
  being merged into the main branch)

- CD: for the changes that are being merged documents are being built and
  pushed to the HelpCenter.

Help Center is implemented as an :ref:`docsportal` instance with no additional reverse proxy used. Since the published content is designed to be public no additional access limitations are applied.

Software Architecture
=====================

A Web-Server (nginx) is listening in the frontend for the requests and based
on the URL decides in which container the data is actually located. It
contacts Storage server and gets the original content from there, which is
then being cached and returned back to the requestor.

.. graphviz:: dot/helpcenter.dot
   :caption: Docs portal software architecture from the protocols point

.. include:: docsportal_sec.rst.inc

Deployment
==========

:git_file:`playbooks/service-docs.yaml` is a playbook for the service
configuration and deployment. It is automatically executed once a pull request
touching any of the affected files (roles, inventory) is being merged.
Additionally it is applied periodically.

Deployment model of the Help Center is as
follows:

* WebServer (nginx) is running as part of the
  K8 deployment and is exposed to the public
  internet via Ingress.

* OpenStack Swift is used as object storage
  with publicly readable container (in a
  dedicated project).
