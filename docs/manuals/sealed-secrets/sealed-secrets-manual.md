# Sealed Secrets User Manual

## Introduction to Sealed Secrets

Sealed Secrets is a Kubernetes controller and client-side utility that allows you to encrypt your Kubernetes Secrets so they can be safely stored in version control systems or public repositories. It solves the problem of securely managing sensitive information like passwords, tokens, and keys in a GitOps workflow.

## How Sealed Secrets Works

1. **Asymmetric Encryption**
   The Sealed Secrets controller generates a public/private key pair. The private key never leaves the cluster. The public key is used to encrypt secrets on your workstation.

2. **Workflow**
   - You create a regular Kubernetes Secret.
   - Using the `kubeseal` CLI tool, you encrypt it with the controller's public key.
   - This creates a SealedSecret custom resource.
   - You commit the SealedSecret to Git and apply it to your cluster.
   - Only the controller can decrypt it, using its private key.

3. **Security Model**
   Even cluster administrators cannot decrypt the secrets without access to the private key. Each SealedSecret is scoped to a specific namespace and name by default.

## Installation

### Install the Controller

```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm install sealed-secrets sealed-secrets/sealed-secrets --namespace sealed-secrets
```

### Install the CLI Tool

```bash
# On macOS with Homebrew
brew install kubeseal

# On Linux
KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | jq -r '.tag_name')
curl -Lo kubeseal "https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64"
chmod +x kubeseal
sudo mv kubeseal /usr/local/bin/
```

## Creating a Sealed Secret

### Method 1: From an Existing Secret File

1.) Create a Kubernetes Secret YAML file, e.g., `my-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
  namespace: myapp
type: Opaque
stringData:
  username: admin
  password: t0p-s3cr3t
```

2.) Seal the Secret

```bash
kubeseal --format yaml --controller-name sealed-secrets-otcinfra2 --controller-namespace sealed-secrets < mysecret.yaml > sealed-secret.yaml
```

### Method 2: Creating Directly from Literal Values

```bash
kubectl create secret generic database-credentials \
  --from-literal=username=admin \
  --from-literal=password=t0p-s3cr3t \
  --dry-run=client -o yaml | \
  kubeseal --format yaml > sealed-secret.yaml
```

### Method 3: Using Annotations for Flexible Scoping

By default, a SealedSecret can only be decrypted if it has the same name and namespace. You can loosen this restriction:

```bash
# Namespace-wide secret (can be decrypted with any name in the same namespace)
kubectl create secret generic database-credentials \
  --from-literal=username=admin \
  --from-literal=password=t0p-s3cr3t \
  --dry-run=client -o yaml | \
  kubeseal --format yaml --scope namespace-wide > sealed-secret.yaml

# Cluster-wide secret (can be decrypted with any name in any namespace)
kubectl create secret generic database-credentials \
  --from-literal=username=admin \
  --from-literal=password=t0p-s3cr3t \
  --dry-run=client -o yaml | \
  kubeseal --format yaml --scope cluster-wide > sealed-secret.yaml
```

## Applying Sealed Secrets

After creating the sealed secret file, apply it to your cluster:

```bash
kubectl apply -f sealed-secret.yaml
```

The controller will automatically decrypt it and create the corresponding Kubernetes Secret.

## Verifying Sealed Secrets

```bash
kubectl get sealedsecret -n myapp
```

## Backup and Recovery

The controller's private key is stored in a Secret in the same namespace as the controller. If lost, all sealed secrets will become undecryptable. It's crucial to back up this key:

```bash
# Export the private key
kubectl get secret -n sealed-secrets sealed-secrets-key -o yaml > sealed-secrets-key-backup.yaml
```

To restore from backup:

```bash
kubectl apply -f sealed-secrets-key-backup.yaml
kubectl delete pod -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets
```

## Best Practices

1. **Backup the controller's private key** - Store it securely outside the cluster.
2. **Use appropriate scoping** - Use the most restrictive scope that meets your needs.
3. **Rotate secrets periodically** - Generate new secrets and seal them again.
4. **Version control** - Store sealed secrets in your Git repository alongside application code.
5. **CI/CD integration** - Automate sealing as part of your pipeline.

## Troubleshooting

If you encounter issues:

1.) Check the controller logs:

```bash
kubectl logs -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets
```

2.) Ensure the SealedSecret is correctly formatted.

```bash
kubeseal --version
```

3.) Verify the controller is running:

```bash
kubectl get pods -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets
```

4.) Ensure the SealedSecret is applied to the correct namespace.

```bash
kubectl get sealedsecret -n myapp
```

## Conclusion

Sealed Secrets provides a secure way to manage Kubernetes secrets in a GitOps workflow. By encrypting your secrets with a key that never leaves the cluster, you can safely store them in Git repositories while maintaining security best practices.
