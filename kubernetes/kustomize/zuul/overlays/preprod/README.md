# Zuul Preprod Environment Configuration

This overlay configures a preprod Zuul environment with multi-tenant support using ArgoCD Vault Plugin for secure secret management.

## Overview

This configuration sets up Zuul with **two tenants**:
- **preprod**: Watches the `preprod` branch for testing and validation
- **production**: Watches the `main` branch for production deployments

## Key Features

### Multi-Tenant Configuration
- Both tenants use the same `opentelekomcloud-infra/system-config` repository
- Tenants watch different branches enabling separate testing and production pipelines
- Tenant configuration is defined in `configs/tenants/main.yaml`

### ArgoCD Vault Plugin Integration
- **No Vault Agent sidecars** - cleaner, more secure deployment
- Secrets are injected at deployment time by ArgoCD Vault Plugin
- Uses `<path:secret/path#key>` syntax for secret references
- Reduces pod complexity and resource usage

### Security Enhancements
- Secrets managed externally by Vault
- No secrets stored in Git repository
- ArgoCD handles secret injection during deployment
- Minimal container privileges required

## Configuration Files

### Tenant Configuration
- `configs/tenants/main.yaml` - Defines preprod and production tenants

### Zuul Configuration
- `configs/zuul.conf.hcl` - Main Zuul configuration with AVP secret paths

### Nodepool Configuration
- `configs/openstack/clouds.yaml.hcl` - OpenStack cloud credentials with AVP paths
- Uses in-cluster Kubernetes authentication (no external kubeconfig needed)

### Kustomize Files
- `kustomization.yaml` - Main kustomization configuration
- `patch-zuul.yaml` - Zuul component patches
- `patch-nodepool.yaml` - Nodepool component patches
- `patch-zuul-executor.yaml` - Executor-specific patches

### RBAC
- `crb.yaml` - ClusterRoleBinding for Vault authentication
- `crb_admin.yaml` - ClusterRoleBinding for admin access

## Deployment

### Prerequisites
1. ArgoCD installed with Vault Plugin configured
2. Vault authentication set up for Kubernetes cluster
3. Secrets configured in Vault at the appropriate paths

### Deploy with ArgoCD
```bash
kubectl apply -f argocd-application.yaml
```

Or use the ArgoCD UI to create the application pointing to:
- Repository: `https://github.com/opentelekomcloud-infra/system-config`
- Branch: `preprod`
- Path: `kubernetes/kustomize/zuul/overlays/zuul_preprod`
- Plugin: `argocd-vault-plugin`

### Manual Deployment (for testing)
```bash
# Build and preview
kustomize build . | argocd-vault-plugin generate -

# Apply with AVP
kustomize build . | argocd-vault-plugin generate - | kubectl apply -f -
```

## Namespace

All resources are deployed to the `zuul` namespace.

## Ingress

The Zuul web interface is accessible at: `https://zuul.eco-preprod.tsi-dev.otc-service.com`

## Differences from Production (zuul_ci)

1. **No Vault Agent sidecars** - Uses ArgoCD Vault Plugin instead
2. **Simplified pod templates** - Fewer init containers and volumes
3. **Tenant-aware** - Explicit multi-tenant configuration
4. **Branch-specific** - Watches preprod branch by default
5. **Separate namespace** - Isolated from production
6. **Enhanced security** - Secrets never touch the cluster except at runtime

## Vault Paths Used

The following Vault paths must be configured:
- `secret/data/zuul/keystore_password`
- `database/static-creds/zuul-static`
- `secret/data/zuul/connections/github`
- `secret/data/zuul/connections/gitlab`
- `secret/data/zuul/connections/gitea`
- `secret/data/smtp_gw`
- `secret/data/clouds/otcci_nodepool_pool[1-3]`
- `secret/data/zuul/sshkey`

## Monitoring

Prometheus metrics are exposed on port 9091 for all Zuul components.

## Maintenance

### Updating Configuration
1. Modify files in this directory
2. Commit and push to `preprod` branch
3. ArgoCD will automatically sync changes

### Viewing Logs
```bash
# Scheduler logs
kubectl -n zuul logs -l app.kubernetes.io/component=zuul-scheduler

# Executor logs
kubectl -n zuul logs -l app.kubernetes.io/component=zuul-executor

# Web logs
kubectl -n zuul logs -l app.kubernetes.io/component=zuul-web
```

### Restarting Components
```bash
# Restart scheduler
kubectl -n zuul rollout restart deployment zuul-scheduler

# Restart executors
kubectl -n zuul rollout restart statefulset zuul-executor
```

## Troubleshooting

### Secrets Not Injected
1. Check ArgoCD Vault Plugin is installed and configured
2. Verify Vault authentication is working
3. Check Vault paths exist and contain required keys

### Tenant Configuration Not Loading
1. Verify `configs/tenants/main.yaml` is mounted correctly
2. Check scheduler logs for tenant loading errors
3. Ensure GitHub connection is configured properly

### Connection Issues
1. Verify network policies allow traffic
2. Check service accounts and RBAC permissions
3. Validate Zookeeper connectivity
