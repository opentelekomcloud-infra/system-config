Install ssl-cert-check

Installs the ssl-cert-check tool and a cron job to check the freshness
of the SSL certificates for the configured domains daily.

**Role Variables**

.. zuul:rolevar:: ssl_cert_check_domain_list
   :default: /var/lib/certcheck/domainlist

   The list of domains to check

.. zuul:rolevar:: ssl_cert_check_days
   :default: 30

   Warn about certificates who have less than this number of days to
   expiry.

.. zuul:rolevar:: ssl_cert_check_email
   :default: root

   The email to send reports to


