Install acme.sh client

This makes the `acme.sh <https://github.com/Neilpang/acme.sh>`__
client available on the host.

Additionally a ``driver.sh`` script is installed to run the
authentication procedure and parse output.

**Role Variables**

.. zuul:rolevar:: letsencrypt_gid
   :default: unset

   Unix group `gid` for the `letsencrypt` group which has permissions
   on the `/etc/letsencrypt-certificates` directory.  If unset, uses
   system default.  Useful if this conflicts with another role that
   assumes a `gid` value.

.. zuul:rolevar:: letsencrypt_account_email
   :default: undefined

   The email address to register with accounts.  Renewal mail and
   other info may be sent here.  Must be defined.
