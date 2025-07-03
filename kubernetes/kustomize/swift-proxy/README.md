# Swift proxy

[zuul-storage-proxy](https://opendev.org/zuul/zuul-storage-proxy) software as a deployment with clouds.yaml populated with vault-agent sidecar.

- currently there is only init side-car => no live credentials rotation support. When creds get rotated - manually rollout the deployment

- there is no ingress. Usually storage-proxy is deployed to have a conntrolled content exposure. Whenever ingress is required it should be implemented by the overlay itself.
