# Zuul New Production Overlay

This overlay deploys Zuul to the **new production** environment on the `otcinfra2` cluster.

## Key Differences from Existing Production (zuul_ci)

| Aspect | prod | zuul_ci (existing) |
|--------|----------|-------------------|
| Namespace | `zuul` | `zuul-ci` |
| Secret Management | ArgoCD Vault Plugin | Vault Agent sidecars |
| Zuul Version | 13.1.1-gitea | change_774_change_859940 |
| Config Branch | `main` | `main` |
| Domain | `zuul.eco.tsi-dev.otc-service.com` | `zuul.otc-service.com` |
| Vault | `vault-k8s.eco.tsi-dev.otc-service.com` | `vault-lb.eco.tsi-dev.otc-service.com` |
| Storage | SFS Turbo NFS + CSI disks | CSI disks only |

## Prerequisites

1. **SFS Turbo NFS** — Update `PLACEHOLDER_SFS_TURBO_IP` in PV files with actual IP
2. **Vault secrets** — Ensure all referenced Vault paths exist in the new Vault instance
3. **DNS** — Configure `zuul.eco.tsi-dev.otc-service.com` and `swift-proxy.eco.tsi-dev.otc-service.com`
4. **ArgoCD** — Add the application definition to deploy this overlay

## TODO before deployment

- [ ] Replace `PLACEHOLDER_SFS_TURBO_IP` in `zuul-config-pv.yaml` and `zuul-scheduler-keys-pv.yaml`
- [ ] Verify Vault paths are accessible from the new Vault instance
- [ ] Configure oauth2-proxy for zuul-web authentication
- [ ] Set up DNS entries for the new domain
