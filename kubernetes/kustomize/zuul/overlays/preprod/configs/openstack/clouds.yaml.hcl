---
# Nodepool openstacksdk configuration for preprod environment
# Using ArgoCD Vault Plugin syntax
cache:
  expiration:
    server: 5
    port: 5
    floating-ip: 5
clouds:
  otcci-pool1:
    auth:
       auth_url: <path:secret/data/clouds/otcci_nodepool_pool1#auth_url>
       user_domain_name: <path:secret/data/clouds/otcci_nodepool_pool1#user_domain_name>
       username: <path:secret/data/clouds/otcci_nodepool_pool1#username>
       password: <path:secret/data/clouds/otcci_nodepool_pool1#password>
       project_name: <path:secret/data/clouds/otcci_nodepool_pool1#project_name>
    private: true
