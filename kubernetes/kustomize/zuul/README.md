# Zuul Environment Separation

This directory contains separated environments for Zuul CI/CD deployment:

## Directory Structure

```
overlays/
├── prod/           # Production environment
│   ├── configs/    # Production-specific configurations
│   └── kustomization.yaml
├── preprod/        # Pre-production environment
│   ├── configs/    # Preprod-specific configurations
│   └── kustomization.yaml
└── zuul_ci/        # Legacy (to be removed)
```

## Environment Differences

### Production (`prod/`)
- **Instance Label**: `zuul-prod`
- **Hostname**: `zuul.otc-service.com`
- **TLS Certificate**: `letsencrypt-prod`
- **Executor Replicas**: 4
- **ZooKeeper Storage**: 10Gi
- **Resource Limits**: Higher (4Gi memory, 2000m CPU)
- **Logging Level**: INFO

### Pre-Production (`preprod/`)
- **Instance Label**: `zuul-preprod`
- **Hostname**: `zuul.eco-preprod.tsi-dev.otc-service.com`
- **TLS Certificate**: `letsencrypt-prod`
- **Executor Replicas**: 1
- **ZooKeeper Storage**: 5Gi
- **Resource Limits**: Lower (2Gi memory, 1000m CPU)
- **Logging Level**: DEBUG

## ArgoCD Vault Integration

Vault Agent has been **removed** and replaced with ArgoCD Vault Plugin integration:

### Removed Components:
- `configMapGenerator` for vault-agent-config
- Vault agent container sidecars
- HCL configuration files (*.hcl)
- Vault authentication mechanisms

### New Approach:
- Configuration files use vault placeholders: `<vault:secret/data/path#key>`
- ArgoCD Vault Plugin processes these during deployment
- Secrets are injected directly into ConfigMaps/Secrets

### Secret Paths:
- **Production**: `vault://secret/data/zuul/prod/`
- **Preprod**: `vault://secret/data/zuul/preprod/`

### Required Vault Secrets:

| Vault Path | Required Keys | Description |
|------------|---------------|-------------|
| `secret/zuul/prod/github` | `app_id`, `app_key` | GitHub App credentials for production |
| `secret/zuul/prod/openstack` | `auth_url`, `username`, `password`, `project_name`, `user_domain_name`, `project_domain_name` | OpenStack authentication for production |
| `secret/zuul/prod/kube` | `ca_cert`, `server`, `token` | Kubernetes cluster access for production |
| `secret/zuul/preprod/github` | `app_id`, `app_key` | GitHub App credentials for preprod |
| `secret/zuul/preprod/openstack` | `auth_url`, `username`, `password`, `project_name`, `user_domain_name`, `project_domain_name` | OpenStack authentication for preprod |
| `secret/zuul/preprod/kube` | `ca_cert`, `server`, `token` | Kubernetes cluster access for preprod |

### Example Vault Commands

```bash
vault kv put secret/zuul/github \
  app_id="YOUR_GITHUB_APP_ID" \
  app_key="YOUR_GITHUB_APP_PRIVATE_KEY"

vault kv put secret/zuul/openstack \
  auth_url="https://iam.eu-de.otc.t-systems.com/v3" \
  username="YOUR_OPENSTACK_USERNAME" \
  password="YOUR_OPENSTACK_PASSWORD" \
  project_name="YOUR_PROJECT_NAME" \
  user_domain_name="OTC00000000001000000xxx" \
  project_domain_name="OTC00000000001000000xxx"

vault kv put secret/zuulkube \
  ca_cert="BASE64_ENCODED_CA_CERT" \
  server="https://your-k8s-api-server:6443" \
  token="K8S_SERVICE_ACCOUNT_TOKEN"


## Deployment

Deploy specific environments using ArgoCD:

```bash
# Production deployment
argocd app create zuul-prod \
  --repo https://github.com/opentelekomcloud-infra/system-config \
  --path kubernetes/kustomize/zuul/overlays/prod \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace zuul

# Preprod deployment
argocd app create zuul-preprod \
  --repo https://github.com/opentelekomcloud-infra/system-config \
  --path kubernetes/kustomize/zuul/overlays/preprod \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace zuul-preprod
```

## Migration from Legacy

The `zuul_ci/` overlay contains the legacy configuration with vault agent.
After successful migration, this can be removed.

## Configuration Management

All sensitive configuration is managed through Vault:
- GitHub App credentials
- OpenStack authentication
- Kubernetes service account tokens
- TLS certificates (managed by cert-manager)

ArgoCD automatically injects these values during deployment.
