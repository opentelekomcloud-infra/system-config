# Vault kubectl Commands Quick Reference

## Environment Setup
```bash
VAULT_POD="vault-0"
VAULT_NS="vault"
VAULT_TOKEN="<root_token>"
UNSEAL_KEY="<unseal_key>"
```

## Basic Operations

### Status & Health
```bash
# Check Vault status
kubectl exec -n $VAULT_NS $VAULT_POD -- vault status

# Check if sealed
kubectl exec -n $VAULT_NS $VAULT_POD -- vault status | grep Sealed

# Unseal Vault
kubectl exec -n $VAULT_NS $VAULT_POD -- vault operator unseal $UNSEAL_KEY

# Login
kubectl exec -n $VAULT_NS $VAULT_POD -- vault login $VAULT_TOKEN
```

## Secrets Management (KV v2)

### Create/Update Secrets
```bash
# Single secret
kubectl exec -n $VAULT_NS $VAULT_POD -- vault kv put secret/argocd/repositories/github \
    username="github-user" \
    password="github-token"

# Multiple fields
kubectl exec -n $VAULT_NS $VAULT_POD -- vault kv put secret/argocd/clusters/otcinfra \
    server="https://kubernetes.default.svc.cluster.local" \
    certData="<certData>" \
    keyData="<keyData>"

# From file
kubectl exec -n $VAULT_NS $VAULT_POD -- vault kv put secret/argocd/config @config.json
```

### Read Secrets
```bash
# Read entire secret
kubectl exec -n $VAULT_NS $VAULT_POD -- vault kv get secret/argocd/repositories/github

# Read specific field
kubectl exec -n $VAULT_NS $VAULT_POD -- vault kv get -field=username secret/argocd/repositories/github

# JSON format
kubectl exec -n $VAULT_NS $VAULT_POD -- vault kv get -format=json secret/argocd/repositories/github
```

### List & Delete Secrets
```bash
# List secrets
kubectl exec -n $VAULT_NS $VAULT_POD -- vault kv list secret/argocd/repositories/
kubectl exec -n $VAULT_NS $VAULT_POD -- vault kv list secret/argocd/clusters/

# Delete secret
kubectl exec -n $VAULT_NS $VAULT_POD -- vault kv delete secret/argocd/repositories/github

# Destroy version (permanent)
kubectl exec -n $VAULT_NS $VAULT_POD -- vault kv destroy -versions=1 secret/argocd/repositories/github
```

## Policy Management

### Create Policy
```bash
# From file
kubectl cp /tmp/argocd-policy.hcl $VAULT_NS/$VAULT_POD:/tmp/policy.hcl
kubectl exec -n $VAULT_NS $VAULT_POD -- vault policy write argocd-policy /tmp/policy.hcl

# Inline policy
kubectl exec -n $VAULT_NS $VAULT_POD -- vault policy write my-policy - <<EOF
path "secret/data/myapp/*" {
  capabilities = ["read"]
}
EOF
```

### Manage Policies
```bash
# List policies
kubectl exec -n $VAULT_NS $VAULT_POD -- vault policy list

# Read policy
kubectl exec -n $VAULT_NS $VAULT_POD -- vault policy read argocd-policy

# Delete policy
kubectl exec -n $VAULT_NS $VAULT_POD -- vault policy delete argocd-policy
```

## Authentication Methods

### Kubernetes Auth
```bash
# Enable Kubernetes auth
kubectl exec -n $VAULT_NS $VAULT_POD -- vault auth enable kubernetes

# Configure Kubernetes auth
kubectl exec -n $VAULT_NS $VAULT_POD -- vault write auth/kubernetes/config \
    token_reviewer_jwt="$(kubectl exec -n $VAULT_NS $VAULT_POD -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host=https://kubernetes.default.svc.cluster.local \
    kubernetes_ca_cert="$(kubectl exec -n $VAULT_NS $VAULT_POD -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)"

# Create auth role
kubectl exec -n $VAULT_NS $VAULT_POD -- vault write auth/kubernetes/role/argocd \
    bound_service_account_names=argocd-repo-server,argocd-server \
    bound_service_account_namespaces=argocd \
    policies=argocd-policy \
    ttl=1h
```

### Role Management
```bash
# List roles
kubectl exec -n $VAULT_NS $VAULT_POD -- vault list auth/kubernetes/role

# Read role
kubectl exec -n $VAULT_NS $VAULT_POD -- vault read auth/kubernetes/role/argocd

# Delete role
kubectl exec -n $VAULT_NS $VAULT_POD -- vault delete auth/kubernetes/role/argocd

# List auth methods
kubectl exec -n $VAULT_NS $VAULT_POD -- vault auth list
```

## Secrets Engines

### Manage Engines
```bash
# List engines
kubectl exec -n $VAULT_NS $VAULT_POD -- vault secrets list

# Enable KV v2
kubectl exec -n $VAULT_NS $VAULT_POD -- vault secrets enable -path=secret kv-v2

# Enable OpenStack plugin
kubectl exec -n $VAULT_NS $VAULT_POD -- vault secrets enable -path=openstack -plugin-name=vault-plugin-secrets-openstack plugin

# Disable engine
kubectl exec -n $VAULT_NS $VAULT_POD -- vault secrets disable openstack
```

## OpenStack Plugin

### Configure OpenStack
```bash
# Configure root credentials
kubectl exec -n $VAULT_NS $VAULT_POD -- vault write openstack/config/root \
    auth_url="https://iam.eu-de.otc.t-systems.com:443/v3" \
    username="openstack-user" \
    password="openstack-password" \
    tenant_name="tenant-name" \
    domain_name="domain-name"

# Create role
kubectl exec -n $VAULT_NS $VAULT_POD -- vault write openstack/roles/my-role \
    user_groups="admin" \
    ttl=1h \
    max_ttl=24h

# Generate credentials
kubectl exec -n $VAULT_NS $VAULT_POD -- vault read openstack/creds/my-role
```

### Manage OpenStack Roles
```bash
# List roles
kubectl exec -n $VAULT_NS $VAULT_POD -- vault list openstack/roles

# Read role
kubectl exec -n $VAULT_NS $VAULT_POD -- vault read openstack/roles/my-role

# Delete role
kubectl exec -n $VAULT_NS $VAULT_POD -- vault delete openstack/roles/my-role
```

## Plugin Management

### Plugin Operations
```bash
# List plugins
kubectl exec -n $VAULT_NS $VAULT_POD -- vault plugin list secret

# Register plugin
kubectl exec -n $VAULT_NS $VAULT_POD -- vault plugin register \
    -sha256=$(kubectl exec -n $VAULT_NS $VAULT_POD -- sha256sum /usr/local/libexec/vault/vault-plugin-secrets-openstack | cut -d' ' -f1) \
    secret vault-plugin-secrets-openstack

# Get plugin info
kubectl exec -n $VAULT_NS $VAULT_POD -- vault plugin info secret vault-plugin-secrets-openstack

# Deregister plugin
kubectl exec -n $VAULT_NS $VAULT_POD -- vault plugin deregister secret vault-plugin-secrets-openstack
```

## Token Management

### Token Operations
```bash
# Create token
kubectl exec -n $VAULT_NS $VAULT_POD -- vault token create -policy=argocd-policy -ttl=1h

# Lookup token
kubectl exec -n $VAULT_NS $VAULT_POD -- vault token lookup $VAULT_TOKEN

# Renew token
kubectl exec -n $VAULT_NS $VAULT_POD -- vault token renew $VAULT_TOKEN

# Revoke token
kubectl exec -n $VAULT_NS $VAULT_POD -- vault token revoke $VAULT_TOKEN
```

## Backup & Recovery

### Snapshot Operations
```bash
# Create snapshot
kubectl exec -n $VAULT_NS $VAULT_POD -- vault operator raft snapshot save backup.snap

# Copy snapshot from pod
kubectl cp $VAULT_NS/$VAULT_POD:backup.snap ./backup-$(date +%Y%m%d).snap

# Restore snapshot
kubectl cp ./backup-20250715.snap $VAULT_NS/$VAULT_POD:restore.snap
kubectl exec -n $VAULT_NS $VAULT_POD -- vault operator raft snapshot restore restore.snap

# List raft peers
kubectl exec -n $VAULT_NS $VAULT_POD -- vault operator raft list-peers
```

## Troubleshooting

### Pod & Logs
```bash
# Check pod status
kubectl get pods -n $VAULT_NS
kubectl describe pod $VAULT_POD -n $VAULT_NS

# Check logs
kubectl logs -n $VAULT_NS $VAULT_POD -c vault
kubectl logs -n $VAULT_NS $VAULT_POD -c download-openstack-plugin

# Plugin directory
kubectl exec -n $VAULT_NS $VAULT_POD -- ls -la /usr/local/libexec/vault/

# Test connectivity
kubectl exec -n $VAULT_NS $VAULT_POD -- curl -s http://localhost:8200/v1/sys/health
```

### Configuration
```bash
# Check config
kubectl exec -n $VAULT_NS $VAULT_POD -- cat /vault/config/config.hcl

# Check storage
kubectl exec -n $VAULT_NS $VAULT_POD -- df -h /vault/data
kubectl exec -n $VAULT_NS $VAULT_POD -- ls -la /vault/data/
```

## API via Port-Forward

### Setup Port-Forward
```bash
# Create port-forward
kubectl port-forward -n $VAULT_NS $VAULT_POD 8200:8200 &

# Set environment
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="<root_token>"
```

### API Commands
```bash
# Health check
curl -s $VAULT_ADDR/v1/sys/health | jq .

# Read secret
curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
    $VAULT_ADDR/v1/secret/data/argocd/repositories/github | jq .

# Write secret
curl -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{"data":{"key":"value"}}' \
    $VAULT_ADDR/v1/secret/data/argocd/test

# List secrets
curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
    $VAULT_ADDR/v1/secret/metadata/argocd/repositories | jq .

# Stop port-forward
pkill -f "kubectl port-forward"
```

## Batch Operations Script

```bash
#!/bin/bash
# vault-batch.sh

VAULT_POD="vault-0"
VAULT_NS="vault"
VAULT_TOKEN="<root_token>"

vault_cmd() {
    kubectl exec -n $VAULT_NS $VAULT_POD -- vault "$@"
}

# Login
vault_cmd login $VAULT_TOKEN

# Create secrets
vault_cmd kv put secret/argocd/repositories/github username="github-user" password="github-token"
vault_cmd kv put secret/argocd/repositories/gitlab username="gitlab-user" password="gitlab-token"

# List secrets
echo "Secrets created:"
vault_cmd kv list secret/argocd/repositories/
```

## Quick Commands

```bash
# Status check
kubectl exec -n vault vault-0 -- vault status

# List everything
kubectl exec -n vault vault-0 -- vault kv list secret/argocd/
kubectl exec -n vault vault-0 -- vault policy list
kubectl exec -n vault vault-0 -- vault auth list
kubectl exec -n vault vault-0 -- vault secrets list

# Emergency unseal
kubectl exec -n vault vault-0 -- vault operator unseal <unseal_key>
kubectl exec -n vault vault-1 -- vault operator unseal <unseal_key>
```
