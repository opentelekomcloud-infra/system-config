# ArgoCD App-of-Apps Infra

Our ArgoCD app-of-apps-infra Helm charts implement the [Argo CD app-of-apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern), designed to deploy Argo CD Application resources. These charts facilitate the configuration of multiple applications that are related or complement each other in functionality.

## Overview

The `app-of-apps-infra` chart does not deploy applications directly but configures Argo CD to manage deployments across multiple environments. It leverages Helm to orchestrate the deployment process, ensuring that applications are deployed consistently as per the defined configurations.

## Features

- **Multi-Cluster Deployment:** Manages infrastructure applications across various Kubernetes clusters.
- **Customizable Configuration:** Allows individual configuration settings for each application.
- **Automation and Self-healing:** Features automated sync policies with self-healing capabilities to maintain applications in their desired state.

## Usage

### Adding New Applications, Clusters and Projects

To add a new application to be managed by Argo CD through this Helm chart:

1. **Define Projects in `values.yaml`:**
   Add new project definitions under the `projects` section. Here you can specify project names, descriptions, and any other relevant configurations:

   ```yaml
   projects:
     - name: prod-project
       description: "Production environment project"
       sourceRepos:
         - 'https://github.com/your-org/*'
       destinations:
         - namespace: 'prod'
           server: 'https://kubernetes.default.svc'
       clusterResourceWhitelist:
         - group: '*'
           kind: '*'
       namespaceResourceBlacklist: []
     - name: dev-project
       description: "Development environment project"
       sourceRepos:
         - 'https://github.com/your-org/*'
       destinations:
         - namespace: 'dev'
           server: 'https://kubernetes.default.svc'
       clusterResourceWhitelist:
         - group: '*'
           kind: '*'
       namespaceResourceBlacklist: []

2. **Define Clusters in `values.yaml`:**
   Add the new cluster details in the `values.yaml` file under the `clusters` section:
   ```yaml
   clusters:
     - name: dev-cluster
     - name: prod-cluster

3. **Define Applications in `values.yaml`:**
   Add the new application's details in the `values.yaml` file under the `applications` section:
   ```yaml
   applications:
     - name: new-app
       clusters: [dev-cluster, prod-cluster]
       config:
         namespace: default
         repoURL: 'https://github.com/your-org/new-app.git'
         targetRevision: main
         path: helm/new-app
         chart: optional-chart-name
         pluginName: optional-plugin
         pluginEnv: 'optional-path-to-chart-values'

### Manual Deployment of Applications

For scenarios that require granular control over deployments, such as initial setups or specific operational tasks, this Helm chart supports manual deployment processes. These processes allow system administrators to deploy the root application, which orchestrates the deployment of all child applications defined in the Helm chart.

#### Steps to Manually Deploy the Root App-of-Apps

 **Navigate to the Manual Deployment Directory:**
   Change to the directory that contains the manual deployment configurations. This typically involves configurations that are not automatically applied by the default Helm deployment process.

   ```bash
   cd path-to-your-repo/kubernetes/argocd-apps/bootstrap/manual
   argocd app create -f root-app-of-apps-infra.yaml
   argocd app sync root-app-of-apps-infra
   argocd app list
   argocd app get root-app-of-apps-infra
