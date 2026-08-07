# APImon Kubernetes Deployment (Kustomize)

Kubernetes deployment for APImon components (scheduler, epmon, executor)
using kustomize for environment-based configuration management.

## Architecture

APImon consists of three main components:

- **Scheduler**: Central task dispatcher (Gearman server on port 4730)
- **EPmon**: Endpoint monitoring - checks cloud service API endpoints
- **Executor**: Executes test scenarios (Gearman client, connects to scheduler)

### Kubernetes Architecture

```
                    +-----------------------------+
                    |   apimon-scheduler Pod      |
                    |                             |
                    |  +-----------------------+  |
                    |  | Scheduler (main)      |  |
                    |  | - Gearman server:4730 |  |
                    |  | - /tmp/scheduler.sock |  |
                    |  +----------+------------+  |
                    |             |               |
                    |  Unix sock  | /tmp/epmon.sock|
                    |             v               |
                    |  +-----------------------+  |
                    |  | EPmon (sidecar)       |  |
                    |  | - Endpoint monitoring |  |
                    |  | - /tmp/epmon.sock     |  |
                    |  +-----------------------+  |
                    +--------------+--------------+
                                   |
                    apimon-gearman | Gearman (4730/TCP)
                    Service (ClusterIP)
                                   |
                    +--------------+--------------+
                    |                             |
        +-----------v----+          +------------v-----------+
        |  apimon-executor (5 replicas)                     |
        |  - Gearman client -> apimon-gearman:4730          |
        |  - Executes test scenarios                        |
        |  - /var/lib/apimon (work dir)                     |
        +--------------------------------------------------+
```

## Directory Structure

```
kubernetes/kustomize/apimon/
├── base/                              # Base deployment (shared defaults)
│   ├── kustomization.yaml
│   ├── scheduler-deployment.yaml      # Scheduler + EPmon sidecar pod
│   ├── executor-deployment.yaml       # Executor deployment (5 replicas)
│   ├── gearman-service.yaml           # Gearman ClusterIP service
│   ├── scheduler-configmap.yaml       # Scheduler/EPmon config templates
│   ├── scheduler-secret.yaml          # Scheduler/EPmon secure config templates
│   ├── executor-configmap.yaml        # Executor config template
│   └── executor-secret.yaml           # Executor secure config template
├── overlays/
│   ├── preprod/                       # Pre-production environment
│   │   ├── kustomization.yaml
│   │   ├── scheduler-patch.yaml
│   │   ├── executor-patch.yaml
│   │   └── configs/                   # Environment-specific configs
│   │       ├── apimon.yaml
│   │       ├── epmon.yaml
│   │       ├── executor.yaml
│   │       ├── scheduler-secure.yaml
│   │       ├── epmon-secure.yaml
│   │       ├── executor-secure.yaml
│   │       └── logging.conf
│   ├── production/                    # Production (eu-de)
│   │   ├── kustomization.yaml
│   │   ├── scheduler-patch.yaml
│   │   ├── executor-patch.yaml
│   │   └── configs/
│   ├── production-swiss/              # Production (Swiss)
│   │   ├── kustomization.yaml
│   │   ├── scheduler-patch.yaml
│   │   ├── executor-patch.yaml
│   │   └── configs/
│   └── hybrid/                        # Hybrid environment
│       ├── kustomization.yaml
│       ├── scheduler-patch.yaml
│       ├── executor-patch.yaml
│       └── configs/
```

## Configuration Mapping (Ansible -> Kubernetes)

### Inventory Variables

| Ansible Variable | Kubernetes Equivalent |
|-----------------|----------------------|
| `apimon_image_stable` | `images[].newTag` in kustomization.yaml |
| `apimon_instances.<name>.statsd_host` | `metrics.statsd.host` in config |
| `apimon_instances.<name>.gearman_host` | `gear[].host` in executor config |
| `apimon_instances.<name>.zone` | `scheduler.zone` / `epmon.zone` |
| `apimon_instances.<name>.epmon_clouds` | `epmon.clouds` in config |
| `apimon_instances.<name>.clouds` | `clouds` in secure config |
| `apimon_instances.<name>.test_projects` | `test_projects` in config |
| `apimon_instances.<name>.test_environments` | `test_environments` in config |
| `apimon_instances.<name>.test_matrix` | `test_matrix` in config |

### VM -> Kubernetes Mapping

| VM Role | Kubernetes |
|---------|-----------|
| scheduler1.apimon.eco.tsi-dev.otc-service.com | apimon-scheduler Deployment (1 replica) |
| preprod.apimon.eco.tsi-dev.otc-service.com | apimon-scheduler Deployment (1 replica, combined scheduler+epmon) |
| executor[1-5].apimon.eco.tsi-dev.otc-service.com | apimon-executor Deployment (5 replicas) |
| hybrid.apimon.eco.tsi-dev.otc-service.com | apimon-scheduler + apimon-executor (1 replica each) |

## Pre-requisites

1. **Kubernetes cluster** with kustomize support (all modern k8s distros)
2. **Image `quay.io/stackmon/apimon:change_68_latest`** accessible from the cluster
3. **Statsd endpoint** - either deploy statsd in-cluster or configure external IP
4. **Alerta endpoint** - configure the `alerta` service URL in configs
5. **Database** (for executor) - PostgreSQL for task results storage

## Networking Requirements

### Intra-cluster

- **Gearman**: Scheduler port 4730/TCP exposed via `apimon-gearman` Service
- **Socket communication**: Scheduler and EPmon share `/tmp` via `emptyDir` volume

### External dependencies

- **Statsd**: UDP port 8125 - configure host in each overlay's config
- **Alerta**: HTTP endpoint - configure in each overlay's config
- **OpenStack clouds**: EPmon needs access to cloud API endpoints

## Deployment

### Preview rendered manifests

```bash
# Pre-production
kustomize build kubernetes/kustomize/apimon/overlays/preprod

# Production
kustomize build kubernetes/kustomize/apimon/overlays/production

# Hybrid
kustomize build kubernetes/kustomize/apimon/overlays/hybrid
```

### Apply to cluster

```bash
# Pre-production (namespace: apimon)
kubectl apply -k kubernetes/kustomize/apimon/overlays/preprod

# Production (namespace: apimon-production)
kubectl apply -k kubernetes/kustomize/apimon/overlays/production

# Hybrid (namespace: apimon-hybrid)
kubectl apply -k kubernetes/kustomize/apimon/overlays/hybrid
```

### Rolling updates

```bash
# Restart scheduler
kubectl rollout restart deployment/apimon-scheduler -n apimon

# Restart executors
kubectl rollout restart deployment/apimon-executor -n apimon
```

## Configuration Management

### Updating the apimon image

Edit `base/kustomization.yaml` or the overlay's `kustomization.yaml`:

```yaml
images:
  - name: apimon
    newName: quay.io/stackmon/apimon
    newTag: change_NN_latest
```

### Updating configs

Configs are derived from Jinja2 templates in `playbooks/templates/apimon/`.
To update a config:

1. Update the Jinja2 template in `playbooks/templates/apimon/`
2. Render the template with the appropriate inventory vars:
   ```bash
   ansible-playbook -i inventory/preprod -e apimon_instance=preprod \
     -e 'apimon={"statsd_host": "192.168.110.207"}' \
     -c local -m debug -a "msg={{ lookup('template', 'playbooks/templates/apimon/scheduler-config.yaml.j2') }}"
   ```
3. Copy the rendered output to the overlay's `configs/` directory

### Secret management

The secure configs contain sensitive data (tokens, passwords, DB URLs).
**Replace all `CHANGE_ME_*` placeholders** before applying:

```bash
# Generate base64-encoded secrets
kubectl create secret generic apimon-scheduler-secret \
  --from-file=scheduler-secure.yaml=./configs/scheduler-secure.yaml \
  --from-file=epmon-secure.yaml=./configs/epmon-secure.yaml \
  --dry-run=client -o yaml > apimon-scheduler-secret.yaml

kubectl create secret generic apimon-executor-secret \
  --from-file=apimon-executor-secure.yaml=./configs/executor-secure.yaml \
  --dry-run=client -o yaml > apimon-executor-secret.yaml
```

## Migration Checklist

- [ ] Deploy statsd/graphite in Kubernetes or configure external endpoint
- [ ] Deploy alerta in Kubernetes or configure external endpoint
- [ ] Set up PostgreSQL database for executor
- [ ] Replace `CHANGE_ME_*` placeholders in secure configs
- [ ] Configure cloud credentials for each environment
- [ ] Test EPmon endpoint monitoring against target clouds
- [ ] Verify executor can connect to scheduler via Gearman
- [ ] Validate test matrix execution
- [ ] Monitor Statsd metrics flow
- [ ] Set up monitoring/alerting for APImon pods
- [ ] Plan VM decommissioning after validation

## Comparison with Ansible Deployment

| Aspect | Ansible (VM) | Kubernetes |
|--------|-------------|------------|
| Runtime | podman/docker | container runtime |
| Service mgmt | systemd | Deployment controller |
| Config | `/etc/apimon/` files | ConfigMaps |
| Secrets | `/etc/apimon/` files | Secrets |
| Scaling | Manual (add VMs) | Replicas in Deployment |
| Networking | Host network / firewalld | Services, NetworkPolicies |
| Config mgmt | Jinja2 templates | Kustomize overlays |
| Updates | Manual restart | Rolling updates |

## Troubleshooting

### Scheduler not accepting Gearman connections

```bash
kubectl exec -it deployment/apimon-scheduler -c scheduler -- netstat -tlnp | grep 4730
kubectl logs deployment/apimon-scheduler -c scheduler
```

### EPmon not sending data to scheduler

Check socket sharing - scheduler and epmon share an `emptyDir` volume at `/tmp`.

```bash
kubectl exec -it deployment/apimon-scheduler -- ls -la /tmp/
```

### Executor can't reach scheduler

Verify the Gearman service DNS resolution:

```bash
kubectl exec -it deployment/apimon-executor -- nslookup apimon-gearman
```

### Statsd metrics not flowing

Verify the statsd host configuration matches your deployment:

```bash
kubectl exec -it deployment/apimon-scheduler -- cat /etc/apimon/apimon.yaml | grep statsd
```
