# Zuul API Proxy

Intelligent HTTPS proxy that routes GitHub API calls based on URL patterns:

- **GitHub App API** (`/app/*`) → real `api.github.com`
- **Gitea repos** (`/repos/infra/*`) → `gitea-api-adapter`
- **Everything else** → real `api.github.com`

## Architecture

```
Zuul Scheduler
    ↓ (HTTPS_PROXY=http://localhost:8080)
    ↓
Zuul API Proxy (sidecar)
    ↓
    ├─→ /app/* ──────────→ api.github.com (GitHub App init)
    ├─→ /repos/infra/* ──→ gitea-api-adapter → Gitea
    └─→ /* ──────────────→ api.github.com (fallback)
```

## Building

```bash
podman build -t quay.io/opentelekomcloud/zuul-api-proxy:1.0.0 -f Containerfile .
podman push quay.io/opentelekomcloud/zuul-api-proxy:1.0.0
```

## Configuration

The proxy runs as a sidecar container in Zuul scheduler/merger pods with:
- Port: 8080
- Environment: `HTTPS_PROXY=http://localhost:8080` in Zuul container
- SSL verification disabled for gitea-api-adapter (self-signed cert)

## Gitea Organizations

Edit `GITEA_ORGS` in `router.py` to add more organizations that should route to Gitea:

```python
GITEA_ORGS = ["infra", "another-org"]
```
