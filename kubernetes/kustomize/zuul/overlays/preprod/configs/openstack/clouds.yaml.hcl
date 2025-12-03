---
# Nodepool openstacksdk configuration for preprod environment
# Using ArgoCD Vault Plugin syntax
cache:
  expiration:
    server: 5
    port: 5
    floating-ip: 5
clouds:
  otcci-pool2:
    auth:
       auth_url: <path:secret/data/clouds/otcci_nodepool_pool2#auth_url>
       user_domain_name: <path:secret/data/clouds/otcci_nodepool_pool2#user_domain_name>
       username: <path:secret/data/clouds/otcci_nodepool_pool2#username>
       password: <path:secret/data/clouds/otcci_nodepool_pool2#password>
       project_name: <path:secret/data/clouds/otcci_nodepool_pool2#project_name>
    private: true
