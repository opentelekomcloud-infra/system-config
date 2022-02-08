:title: Documentation Portal

.. _docsportal:

Documentation Portal
####################

Documentation portal is a web server that serves documentation maintained by
various git projects.

At a Glance
===========

:Hosts:
  * https://docs.otc-service.com
:Projects:
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

Integration of projects under the :ref:`Zuul` allows following:

- CI for the changes in the project (i.e. only tested and approved content is
  being merged into the main branch)

- CD: for the changes that are being merged documents are being built and
  pushed to the HelpCenter.


Software Architecture
=====================

A Web-Server (nginx) is listening in the frontend for the requests and based
on the URL decides in which container the data is actually located. It
contacts Storage server and gets the original content from there, which is
then being cached and returned back to the requestor.

.. graphviz:: dot/docsportal.dot
   :caption: Docs portal software architecture

.. include:: docsportal_sec.rst.inc

Deployment
==========

:git_file:`playbooks/service-docs.yaml` is a playbook for the service
configuration and deployment. It is automatically executed once a pull request
touching any of the affected files (roles, inventory) is being merged.
Additionally it is applied periodically.
