# graphite (go-carbon + statsd) — Zuul-metrics carbon store

k8s port of the ansible-managed `graphite1.eco` VM (the carbonapi `zuul` backend
store). Runs the bundled `graphite-statsd` image as a StatefulSet: whisper on a
`csi-disk-retain` PVC, `carbonserver :8081` for carbonapi, statsd `:8125` +
carbon `:2003/:2004` ingest.

**Status: un-wired** (like `local/grafana`, `local/alerta`). Add the ArgoCD app
entry in `local/argocd/values/prod/values-argocd-applications.yaml` to deploy.
Target cluster: **otcinfra**, namespace **graphite** (co-located with carbonapi).

## Ingest options (external producers only)

In-cluster producers (cloudmon, carbonapi) reach go-carbon via the ClusterIP
Service — nothing extra. For external producers pick ONE:

| Option | Set | Producer points at | When |
|---|---|---|---|
| **NodePort** (recommended) | `nodePortIngest.enabled: true` | `<otcinfra node IP on 192.168.170.x>:31825/udp` | default; no ELB to provision |
| Dedicated ELB VIP | `loadBalancer.enabled: true` (+ `elb.subnet-id`/`autocreate`) | ELB VIP `:8125/udp` | only if a stable VIP is preferred |

> **UDP caveat:** statsd is UDP:8125. Per CCE docs, UDP listeners work **only on
> dedicated (`elb.class: performance`) ELBs** — the shared (`union`) internal
> ELBs cannot do UDP. NodePort avoids this entirely.

## Networking prerequisites (zero-VM aligned)

- **VPC peering / VPN: none needed.** The swift controller VM already routes to
  otcinfra `192.168.170.0/24`, and `otcinfra ↔ otcinfra2` (`170 ↔ 171`) is
  already peered (`otcinfra2-domain2_infra_de`). All endpoints are intra-OTC eu-de.
- **Security group: one rule missing.** Allow the chosen UDP port (NodePort
  `31825` or ELB `8125`) inbound on the otcinfra worker nodes / ELB from:
  - `192.168.80.0/24` (swift subnet — transitional producer), and
  - `192.168.171.0/24` (otcinfra2 — end-state k8s producers).

## Recommended sequencing (toward zero VMs)

1. **B1** — retire the haproxy proxies (removes one historic statsd source).
2. **swift → k8s** — once swift is k8s-native, its statsd emits in-cluster or
   over the existing `170 ↔ 171` peering.
3. **B2 cutover** — deploy this chart, seed the 2.9 GiB whisper, repoint the
   carbonapi `zuul` backend + the (now k8s) swift producer, retire `graphite1.eco`,
   then drop the transitional swift-subnet SG rule.

Full step-by-step: `B2-GRAPHITE-CUTOVER-RUNBOOK.md` (repo root of the workspace).
