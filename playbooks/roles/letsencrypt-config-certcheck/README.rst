Generate SSL check list

This role automatically generates a list of domains for the
certificate validation checks.  This ensures our certificates are
valid and are being renewed as expected.

This role must run after ``letsencrypt-request-certs`` role, as that
builds the ``letsencrypt_certcheck_domains`` variable for each
host and certificate.  It must also run on a host that has already run
the ``install-certcheck`` role.

**Role Variables**

.. zuul:rolevar:: letsencrypt_certcheck_domain_list
   :default: /var/lib/certcheck/ssldomains

   The ssl-cert-check domain configuration file to write.  See also
   the ``install-certcheck`` role.

.. zuul:rolevar:: letsencrypt_certcheck_additional_domains
   :default: []

   A list of additional domains to check for hosts not using the
   ``letsencrypt-*`` roles.  Each entry should be in the format
   ``hostname port``.


