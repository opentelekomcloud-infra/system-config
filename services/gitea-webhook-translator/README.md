# Gitea to GitHub Webhook Translator

This service translates Gitea webhook payloads to GitHub format for Zuul CI/CD processing.

## Problem

Zuul's GitHub driver doesn't recognize Gitea webhook payloads because:
- Gitea sends `X-Gitea-Signature` headers
- GitHub expects `X-Hub-Signature-256` headers
- Payload structures differ slightly

## Solution

This translator service:
1. Receives webhooks from Gitea
2. Converts the payload to GitHub format
3. Signs it with GitHub webhook secret
4. Forwards to Zuul's GitHub webhook endpoint

## Build and Deploy

### Build Docker Image

```bash
cd services/gitea-webhook-translator
docker build -t registry.eco-preprod.tsi-dev.otc-service.com/gitea-webhook-translator:latest .
docker push registry.eco-preprod.tsi-dev.otc-service.com/gitea-webhook-translator:latest
```

### Deploy to Kubernetes

```bash
kubectl apply -k kubernetes/kustomize/gitea-webhook-translator/overlays/preprod/
```

## Configuration

### Environment Variables

- `ZUUL_WEBHOOK_URL`: Zuul's GitHub webhook endpoint (default: `http://zuul-web.zuul.svc.cluster.local:9000/api/connection/github/payload`)
- `GITHUB_WEBHOOK_SECRET`: GitHub connection webhook secret from Vault
- `GITEA_WEBHOOK_SECRET`: (Optional) Gitea webhook secret for signature verification

### Secrets (in Vault)

```bash
# GitHub webhook secret (already exists)
vault kv get secret/zuul/connections/github

# Gitea webhook secret (optional)
vault kv put secret/zuul/connections/gitea webhook_token="<random-secret>"
```

## Configure Gitea Webhook

1. Go to your Gitea repository settings
2. Navigate to Webhooks → Add Webhook → Gitea
3. Set URL: `https://zuul.eco-preprod.tsi-dev.otc-service.com/api/webhook/gitea/webhook`
4. Set Secret: (leave empty or use GITEA_WEBHOOK_SECRET value)
5. Select events: Push, Pull Request
6. Set to Active

## Testing

```bash
# Check service health
curl https://zuul.eco-preprod.tsi-dev.otc-service.com/api/webhook/gitea/health

# View logs
kubectl -n zuul logs -f deployment/gitea-webhook-translator
```

## Troubleshooting

### Webhook delivery fails with 401

Check that the GitHub webhook secret matches:
```bash
vault kv get secret/zuul/connections/github
kubectl -n zuul get secret gitea-webhook-translator -o yaml
```

### Zuul doesn't trigger builds

1. Check translator logs:
   ```bash
   kubectl -n zuul logs -f deployment/gitea-webhook-translator
   ```

2. Check Zuul scheduler logs:
   ```bash
   kubectl -n zuul logs -f deployment/zuul-scheduler | grep "infra/system-config"
   ```

3. Verify ingress is working:
   ```bash
   kubectl -n zuul get ingress gitea-webhook-translator
   ```

### Payload conversion issues

The translator logs show the received and converted payloads. Check for any conversion errors in the logs.
