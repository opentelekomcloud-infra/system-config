Install and configure Ansible on a host via pip

This will install ansible into a virtualenv at ``/usr/ansible-venv``

**Role Variables**

.. zuul:rolevar:: install_ansible_requirements
   :default: [ansible, openstacksdk]

   The packages to install into the virtualenv.  A list in Python
   ``requirements.txt`` format.

.. zuul:rolevar:: install_ansible_collections
   :default: undefined

   A list of Ansible collections to install.  In the format

   ..
      - namespace:
        name:
        repo:

.. zuul:rolevar:: install_ansible_ara_enable
   :default: false

   Whether or not to install the ARA Records Ansible callback plugin
   into Ansible.  If using the default
   ``install_ansible_requirements`` will install the ARA package too.

.. zuul:rolevar:: install_ansible_ara_config

   A dictionary of configuration keys and their values for ARA's Ansible plugins.

   Default configuration keys:

   - ``api_client: offline`` (can be ``http`` for sending to remote API servers)
   - ``api_server: http://127.0.0.1:8000`` (has no effect when using offline)
   - ``api_username: null`` (if required, an API username)
   - ``api_password: null`` (if required, an API password)
   - ``api_timeout: 30`` (the timeout on http requests)

   For a list of available configuration options, see the `ARA documentation`_

.. _ARA documentation: https://ara.readthedocs.io/en/latest/ara-plugin-configuration.html
