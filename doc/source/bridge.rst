:title: Bridge

.. _bridge:

Bridge
######

Bridge is a bastion host that is the starting point for ops operations in
OpenTelekomCloudEco. It is the server from which Ansible is run, and contains
decrypted secure information such as passwords.  The bridge server contains all
of the ansible playbooks as well as the scripts to create new servers.

Sensitive information like passwords is stored encrypted in the private git and
are pulled by the bridge host on a cron basis.

At a Glance
===========

:Projects:
  * https://ansible.com/
:Bugs:
:Resources:

Ansible Hosts
-------------
In OTC Eco, all host configuration is done via ansible playbooks.

Adding a node
-------------

In principle hosts in the inventory (``inventory/base/hosts.yaml``) contain
required variables so that playbooks are able to provision the infrastructure.
This is not yet implemented for all hosts/systems.

.. _running-ansible-on-nodes:

Running Ansible on Nodes
------------------------

Each service that has been migrated fully to Ansible has its own playbook in
:git_file:`playbooks` named ``service_{ service_name }.yaml``.

Because the playbooks are normally run by zuul, to run them manually, first run
the utility ``disable-ansible`` as root. That will touch the file
``/home/zuul/DISABLE-ANSIBLE``. We use the utility to avoid mistyping the
lockfile name. Then make sure no jobs are currently executing ansible. Ensure
that ``/home/zuul/src/github.com/opentelekomcloud-infra/system-config`` is in
the appropriate state, then run:

.. code-block:: bash

  cd /home/zuul/src/github.com/opentelekomcloud-infra/system-config
  ansible-playbook --limit="$HOST:localhost" playbooks/service-$SERVICE.yaml

as root, where `$HOST` is the host you want to run puppet on.
The `:localhost` is important as some of the plays depend on performing a task
on the localhost before continuing to the host in question, and without it in
the limit section, the tasks for the host will have undefined values.

When done, don't forget to remove ``/home/zuul/DISABLE-ANSIBLE``

Disabling Ansible on Nodes
--------------------------

In the case of needing to disable the running of ansible on a node, it's a
simple matter of adding an entry to the ansible inventory "disabled" group.
