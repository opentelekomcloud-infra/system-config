# ArgoCD with Vault Integration

This ArgoCD deployment is configured to integrate with HashiCorp Vault for secret management.

## Prerequisites

Before deploying ArgoCD, you need to create a Vault token secret that will be used by ArgoCD to authenticate with Vault and retrieve secrets.

### Create Vault Token Secret

The vault-token secret must be created before deploying ArgoCD:

```bash
kubectl create secret generic vault-token --from-literal=token=<root_token> -n argocd
```

Replace `<root_token>` with your actual Vault root token or a token with appropriate permissions to read secrets from the `secret/argocd/config` path.

## Deployment

After creating the vault-token secret, you can deploy ArgoCD with:

```bash
helm upgrade --install argocd . --namespace argocd --create-namespace --values values-preprod.yaml
```

## Vault Integration Details

ArgoCD is configured to:
- Retrieve admin password from Vault at `secret/argocd/config`
- Use direct token authentication with Vault
- Automatically patch the argocd-secret with resolved values from Vault
- Support the ArgoCD Vault Plugin (AVP) for Application manifests
