# Kustomize stack for installing Zuul

This folder contains Kubernetes manifests processed by Kustomize application in
order to generate final set of manifests for installing Zuul into the
Kubernetes.

## Components

Whole installation is split into individual components, so that it is possible
to configure what to use in a specific installation:

### ca

Zuul requires Zookeeper in HA mode with TLS enabled to function. It is possible
to handle TLS outside of the cluster, but it is also possible to rely on
cert-manager capability of having own CA authority and provide certificates as
requested. At the moment this is set as a hard dependency in the remaining
components, but it would be relatively easy to make it really optional
component.

### Zookeeper

This represents a Zookeeper cluster installation. No crazy stuff, pretty
straigt forward

### zuul-scheduler

Zuul scheduler

### zuul-executor

Zuul executor

### zuul-merger

Optional zuul-merger

### zuul-web

Zuul web frontend

### nodepool-launcher

Launcher for VMs or pods

### nodepool-builder

Optional builder for VM images. At the moment it is not possible to build all
types of images inside of Kubernetes, since running podman under docker in K8
is not working smoothly on every installation

## Layers

- `base` layer is representing absolutely minimal installaiton. In the
  kustomization.yaml there is a link to zuul-config repository which must
  contain `nodepool/nodepool.yaml` - nodepool config and `zuul/main.yaml` -
  tenants info.  This link is given by `zuul_instance_config` configmap with
  ZUUL_CONFIG_REPO=https://gitea.eco.tsi-dev.otc-service.com/scs/zuul-config.git

- `zuul_ci` - zuul.otc-service.com installation

## Versions

Zookeeper version is controlled through
`components/zookeeper/kustomization.yaml`

Zuul version by default is pointing to the latest version in docker registry
and it is expected that every overlay is setting desired version.

Proper overlays are also relying on HashiCorp Vault for providing installation
secrets. Vault agent version is controlled i.e. in the overlay itself with
variable pointing to the vault installation in the overlay patch.
