:title: Zuul

Zuul
####

Zuul is a pipeline-oriented project gating system.  It facilitates
running tests and automated tasks in response to Code Review events.

At a Glance
===========

:Hosts:
  * https://zuul.otc-service.com
:Projects:
  * https://opendev.org/zuul/zuul
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
`<https://zuul.opendev.org/>`_.

.. _Zuul Reference Manual: https://zuul-ci.org/docs/zuul
.. _Zuul Status Page: http://zuul.otc-service.com
