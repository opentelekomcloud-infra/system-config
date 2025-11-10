# Zuul Preprod ArgoCD Vault Plugin Migration

This document describes the migration from vault-agent to ArgoCD vault plugin for the zuul_ci overlay, converted to a preprod environment.

## 🔄 **Migration Summary**

### **Before: Vault Agent (zuul_ci overlay)**
- Used HCL templates with `{{- with secret "path" }}` syntax
- Required vault agent sidecars in pods
- Complex two-level secret lookups for OpenStack credentials

### **After: ArgoCD Vault Plugin (preprod overlay)**
- Uses `<vault:secret/data/path#key>` syntax
- Direct secret injection by ArgoCD
- Simplified single-level secret paths

## 📋 **Required Vault Secrets for Preprod Environment**

### **1. Zuul Configuration Secrets**
```bash
# Keystore password
vault kv put secret/zuul/preprod/keystore_password \
  password="your-keystore-password"

# Database credentials
vault kv put secret/zuul/preprod/database \
  username="zuul_preprod" \
  password="your-db-password" \
  host="192.168.21.246" \
  dbname="zuul_preprod"

# SSH key for Zuul operations
vault kv put secret/zuul/preprod/sshkey \
  private_key="-----BEGIN PRIVATE KEY-----
...your-ssh-private-key...
-----END PRIVATE KEY-----"

# SMTP gateway credentials
vault kv put secret/zuul/preprod/smtp_gw \
  username="your-smtp-username" \
  password="your-smtp-password"
```

### **2. Connection Secrets**
```bash
# GitHub App credentials
vault kv put secret/zuul/preprod/connections/github \
  webhook_token="your-github-webhook-token" \
  app_id="your-github-app-id" \
  app_key="-----BEGIN RSA PRIVATE KEY-----
...your-github-app-private-key...
-----END RSA PRIVATE KEY-----"

# GitLab credentials
vault kv put secret/zuul/preprod/connections/gitlab \
  api_token="your-gitlab-api-token" \
  webhook_token="your-gitlab-webhook-token" \
  ssh_key="-----BEGIN PRIVATE KEY-----
...your-gitlab-ssh-key...
-----END PRIVATE KEY-----"

# Gitea credentials
vault kv put secret/zuul/preprod/connections/gitea \
  api_token="your-gitea-api-token" \
  webhook_secret="your-gitea-webhook-secret" \
  ssh_key="-----BEGIN PRIVATE KEY-----
...your-gitea-ssh-key...
-----END PRIVATE KEY-----"
```

### **3. OpenStack Cloud Credentials**
```bash
# Pool 1 credentials
vault kv put secret/zuul/preprod/clouds/otcci_nodepool_pool1 \
  auth_url="https://iam.eu-de.otc.t-systems.com/v3" \
  username="nodepool-pool1-user" \
  password="your-pool1-password" \
  project_name="eu-de_nodepool_pool1" \
  user_domain_name="OTC00000000001000000449" \
  project_domain_name="OTC00000000001000000449"

# Pool 2 credentials
vault kv put secret/zuul/preprod/clouds/otcci_nodepool_pool2 \
  auth_url="https://iam.eu-de.otc.t-systems.com/v3" \
  username="nodepool-pool2-user" \
  password="your-pool2-password" \
  project_name="eu-de_nodepool_pool2" \
  user_domain_name="OTC00000000001000000449" \
  project_domain_name="OTC00000000001000000449"

# Pool 3 credentials
vault kv put secret/zuul/preprod/clouds/otcci_nodepool_pool3 \
  auth_url="https://iam.eu-de.otc.t-systems.com/v3" \
  username="nodepool-pool3-user" \
  password="your-pool3-password" \
  project_name="eu-de_nodepool_pool3" \
  user_domain_name="OTC00000000001000000449" \
  project_domain_name="OTC00000000001000000449"
```

### **4. Kubernetes Credentials**
```bash
# Kubernetes cluster access
vault kv put secret/zuul/preprod/kube \
  server="https://your-k8s-api-server:6443" \
  ca_cert="LS0tLS1CRUdJTi...your-base64-ca-cert...LS0tLS0K" \
  token="your-service-account-token"
```

## 🔧 **Key Changes Made**

### **1. Updated Container Images**
- Zuul: `change_774_change_859940` → `9.4.0` (latest stable)
- Nodepool: `8.2.0` → `9.0.0` (latest stable)
- Busybox: `1.36.0-musl` → `1.36.1` (security updates)

### **2. Enhanced Security**
- Added comprehensive security contexts
- Implemented resource limits for preprod
- Added security headers to ingress
- Created network policies

### **3. Environment-Specific Configuration**
- Domain: `zuul.eco-preprod.tsi-dev.otc-service.com`
- Reduced replicas for cost optimization
- Preprod-specific resource limits
- Environment-specific vault paths

### **4. Removed Vault Agent Dependencies**
- No more vault agent sidecars
- Simplified pod configurations
- Direct ArgoCD vault integration
- Reduced resource usage

## 🚀 **Deployment Instructions**

1. **Create all vault secrets** using the commands above
2. **Deploy using ArgoCD** pointing to the preprod overlay
3. **Verify vault plugin** is injecting secrets correctly
4. **Test connectivity** to all external services

## 🔍 **Verification Commands**

```bash
# Test kustomize build
kubectl kustomize /path/to/preprod/overlay

# Check ArgoCD vault plugin logs
kubectl logs -n argocd argocd-server-xxx | grep vault

# Verify secret injection
kubectl get secret zuul-config -n zuul-preprod -o yaml
```

The migration eliminates vault agent complexity while maintaining all functionality with improved security and resource efficiency.
