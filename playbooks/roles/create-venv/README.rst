Create a venv

You would think this role is unnecessary and roles could just install
a ``venv`` directly ... except sometimes pip/setuptools get out of
date on a platform and can't understand how to install compatible
things.  For example the pip shipped on Bionic will upgrade itself to
a version that doesn't support Python 3.6 because it doesn't
understand the metadata tags the new version marks itself with.  We've
seen similar problems with wheels.  History has shown that whenever
this problem appears solved, another issue will appear.  So for
reasons like this, we have this as a synchronization point for setting
up venvs.

**Role Variables**

.. zuul:rolevar:: create_venv_path
   :default: unset

   Required argument; the directory to make the ``venv``
