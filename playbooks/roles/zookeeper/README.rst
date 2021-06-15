Install, configure and run Zookeeper container under SystemD


**Role Variables**

.. zuul:rolevar:: ssl_ca_path

   Path to x509 CA file on localhost to be copied over.

.. zuul:rolevar:: ssl_cert_path

   Path to the private x509 cert on locahost for the ZK.

.. zuul:rolevar:: ssl_key_path

   Path to the private key in pcks8 format to be used by ZK.

.. zuul:rolevar:: zookeeper_image
   :default: quay.io/opentelekomcloud/zookeeper:3.7.0

   Image name.

.. zuul:rolevar:: zookeeper_os_group
   :default: zookeeper

   OS group name to be running zookeeper service.

.. zuul:rolevar:: zookeeper_autopurge_interval
   :default: []

   Autopurge interval for ZK.

.. zuul:rolevar:: zookeeper_tick_time
   :default: [2000]

   ZK Tick time.

.. zuul:rolevar:: zookeeper_init_limit
   :default: [10]

   ZK init limit.

.. zuul:rolevar:: zookeeper_sync_limit
   :default: [5]

   ZK sync limit.

.. zuul:rolevar:: zookeeper_instance_group
   :default: [zookeeper]

   Ansible inventory group name. Members of this group will build single cluster.

.. zuul:rolevar:: zookeeper_cluster_ports
   :default: [2888:3888]

   Cluster ports setting for the hosts in the cluster.
