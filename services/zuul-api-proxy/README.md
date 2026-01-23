# Zuul API Proxy

Intelligent HTTPS proxy that routes GitHub API calls based on URL patterns, enabling Zuul to work with both GitHub and Gitea simultaneously.

## Problem Statement

Zuul's GitHub driver hardcodes `api.github.com` for API calls, ignoring the `baseurl` configuration. This prevents using Gitea as a GitHub-compatible alternative because:
- Zuul needs to authenticate with GitHub App API (`/app/*` endpoints)
- Gitea repository operations need different API paths (`/api/v1/repos/*` instead of `/repos/*`)
- Changing DNS or host aliases breaks GitHub App SSL verification

## Solution: mitmproxy-based Intelligent Proxy

A sidecar container running mitmproxy with custom routing logic that intercepts HTTPS requests from Zuul and routes them based on URL patterns.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Zuul Pod                                │
│                                                                 │
│  ┌──────────────────┐          ┌─────────────────────────────┐ │
│  │  Zuul Container  │          │  zuul-api-proxy (sidecar)   │ │
│  │                  │          │                             │ │
│  │  Environment:    │          │  mitmproxy:10.4.2           │ │
│  │  HTTPS_PROXY=    │          │  + router.py                │ │
│  │  localhost:8080  │──────────►  + entrypoint.sh            │ │
│  │                  │          │                             │ │
│  │  REQUESTS_CA_    │          │  Port: 8080                 │ │
│  │  BUNDLE=/        │          │                             │ │
│  │  mitmproxy-ca/   │◄─────────│  CA cert: shared via        │ │
│  │  cert.pem        │ CA cert  │  emptyDir volume            │ │
│  └──────────────────┘          └─────────────────────────────┘ │
│           │                                  │                  │
│           │ Shared Volume: /mitmproxy-ca     │                  │
│           └──────────────────────────────────┘                  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               │ Routing Logic
                               ↓
           ┌────────────────────┴──────────────────┐
           │                                       │
           ↓                                       ↓
    /app/* requests                    /repos/infra/* requests
           │                                       │
           ↓                                       ↓
    api.github.com                        gitea-api-adapter
    (GitHub App API)                      (ClusterIP Service)
    - /app/installations                          │
    - /app/installations/{id}/access_tokens       │
                                                   ↓
                                          Gitea API Adapter
                                          (FastAPI Service)
                                          - Translates paths:
                                            /repos/* → /api/v1/repos/*
                                                   │
                                                   ↓
                                          gitea.eco.tsi-dev.otc-service.com
                                          (Gitea v1.25.4)
```

## Components

### 1. zuul-api-proxy (this service)
- **Technology**: mitmproxy 10.4.2
- **Function**: Intelligent HTTPS proxy with custom routing
- **Routing Rules**:
  - `/app/*` → `api.github.com` (GitHub App authentication)
  - `/repos/{org}/*` where `{org}` in `GITEA_ORGS` → `gitea-api-adapter`
  - Everything else → `api.github.com` (fallback)

### 2. gitea-api-adapter
- **Technology**: FastAPI
- **Function**: API path translation service
- **Translation**: `/repos/*` → `/api/v1/repos/*`
- **Target**: Gitea API at `gitea.eco.tsi-dev.otc-service.com`

### 3. gitea-webhook-translator
- **Technology**: FastAPI
- **Function**: Webhook format conversion
- **Translation**: Gitea webhooks → GitHub webhook format
- **Target**: Zuul webhook endpoint

## Deployment

### Building the Image

```bash
# Build for linux/amd64 (required for cluster)
cd services/zuul-api-proxy
podman build --platform linux/amd64 -t quay.io/opentelekomcloud/zuul-api-proxy:1.0.2 .
podman push quay.io/opentelekomcloud/zuul-api-proxy:1.0.2
```

### Kubernetes Configuration

The proxy is deployed as a sidecar in Zuul scheduler and merger pods:

```yaml
containers:
  - name: zuul
    env:
      - name: HTTPS_PROXY
        value: "http://localhost:8080"
      - name: HTTP_PROXY
        value: "http://localhost:8080"
      - name: NO_PROXY
        value: "localhost,127.0.0.1,.svc.cluster.local,zookeeper.zuul.svc.cluster.local"
      - name: REQUESTS_CA_BUNDLE
        value: "/mitmproxy-ca/mitmproxy-ca-cert.pem"
      - name: CURL_CA_BUNDLE
        value: "/mitmproxy-ca/mitmproxy-ca-cert.pem"
      - name: SSL_CERT_FILE
        value: "/mitmproxy-ca/mitmproxy-ca-cert.pem"
    volumeMounts:
      - name: mitmproxy-ca
        mountPath: /mitmproxy-ca
        readOnly: true

  - name: api-proxy
    image: quay.io/opentelekomcloud/zuul-api-proxy:1.0.2
    imagePullPolicy: Always
    ports:
      - containerPort: 8080
        name: proxy
    volumeMounts:
      - name: mitmproxy-ca
        mountPath: /mitmproxy-ca

volumes:
  - name: mitmproxy-ca
    emptyDir: {}
```

### CA Certificate Initialization

The entrypoint script ensures proper initialization:

1. Start mitmproxy in background
2. Wait up to 10 seconds for CA certificate generation
3. Copy CA cert to shared volume `/mitmproxy-ca/`
4. Zuul container reads cert via `REQUESTS_CA_BUNDLE`

## Configuration

### Adding More Gitea Organizations

Edit `GITEA_ORGS` in [router.py](router.py):

```python
GITEA_ORGS = ["infra", "another-org", "third-org"]
```

### Zuul Connection Configuration

In `zuul.conf`:

```ini
[connection "gitea"]
driver=github
baseurl=https://gitea-api-adapter.zuul.svc.cluster.local
git_url=ssh://git@gitea.eco.tsi-dev.otc-service.com:2222/%%(project)s
verify_ssl=false
```

**Note**: `baseurl` points to gitea-api-adapter but is ignored by Zuul for API calls. The proxy handles routing instead.

## Verification

### Check Proxy Logs

```bash
kubectl logs -n zuul deployment/zuul-scheduler -c api-proxy
```

Expected output shows routing decisions:
```
[::1]:55862: GET https://api.github.com/app/installations
server connect api.github.com:443 (140.82.121.6:443)

[::1]:55890: GET https://gitea-api-adapter.zuul.svc.cluster.local/repos/infra/...
server connect gitea-api-adapter.zuul.svc.cluster.local:443 (10.247.122.183:443)
```

### Verify CA Certificate

```bash
kubectl exec -n zuul deployment/zuul-scheduler -c zuul -- \
  ls -la /mitmproxy-ca/mitmproxy-ca-cert.pem
```

### Check Zuul Scheduler Status

```bash
kubectl get pods -n zuul -l app.kubernetes.io/component=zuul-scheduler
```

Should show `2/2 Ready`.

## Troubleshooting

### Readiness Probe Failures

- **Symptom**: Pod shows `1/2 Ready`, readiness probe returns 503
- **Cause**: Scheduler initialization takes time (GitHub App auth, ZooKeeper connection)
- **Solution**: Wait 2-5 minutes for initialization to complete

### SSL Certificate Errors

- **Symptom**: `OSError: Could not find a suitable TLS CA certificate bundle`
- **Cause**: CA cert not copied before Zuul starts
- **Solution**: Fixed in v1.0.2 with entrypoint script waiting for cert generation

### Architecture Mismatches

- **Symptom**: `exec format error`
- **Cause**: Built for wrong architecture (arm64 vs amd64)
- **Solution**: Always build with `--platform linux/amd64`

### Proxy Not Routing Correctly

- **Symptom**: Requests not reaching gitea-api-adapter
- **Cause**: Organization not in `GITEA_ORGS` list
- **Solution**: Add organization to `router.py` and rebuild

## Version History

- **v1.0.0** (arm64) - Initial implementation, wrong architecture
- **v1.0.0** (amd64) - Architecture fix, SSL certificate timing issues
- **v1.0.1** - CMD-based CA cert copy, still had timing issues
- **v1.0.2** - Entrypoint script with proper initialization, **CURRENT STABLE**

## Related Services

- [gitea-api-adapter](../gitea-api-adapter/) - API path translation
- [gitea-webhook-translator](../gitea-webhook-translator/) - Webhook format conversion
