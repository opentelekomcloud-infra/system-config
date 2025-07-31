pid_file = "/home/vault/pidfile"
auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes"
        config = {
            role = "backstage"
            token_path = "/var/run/secrets/tokens/vault-token"
        }
    }
    sink "file" {
        config = {
            path = "/home/vault/.vault-token"
        }
    }
}

api_proxy {
  use_auto_auth_token = "force"
  enforce_consistency = "always"
}

listener "tcp" {
  address = "127.0.0.1:8100"
  tls_disable = true
}

template {
  destination = "/secrets/app-config.production.yaml"
  contents = <<EOT
app:
  baseUrl: https://backstage-dev.eco-preprod.tsi-dev.otc-service.com

backend:
  auth:
  # TODO: once plugins have been migrated we can remove this, but right now it
  # is require for the backend-next to work in this repo
    dangerouslyDisableDefaultAuthPolicy: true
  # Used for enabling authentication, secret is shared by all backend plugins
  # See https://backstage.io/docs/auth/service-to-service-auth for
  # information on the format
  # auth:
  #   keys:
  #     - secret: ${BACKEND_SECRET}

  baseUrl: https://backstage-dev.eco-preprod.tsi-dev.otc-service.com
  listen:
    port: 7007
  cors:
    origin: https://backstage-dev.eco-preprod.tsi-dev.otc-service.com

auth:
  environment: production

catalog:
  rules:
    - allow: [Component, System, API, Resource, Location, Group, User, Template]
  locations:
    # General
    - type: url
      target: https://gitea.eco-preprod.tsi-dev.otc-service.com/backstage/catalog/contents/blob/main/otc-catalog.yaml
      rules:
        - allow: [Domain, Group, User, Location, Component, Resource, API, System]
    # Compute
    - type: url
      target: https://gitea.eco-preprod.tsi-dev.otc-service.com/backstage/catalog-compute/contents/blob/main/catalog.yaml
    # Ecosystem
    - type: url
      target: https://gitea.eco-preprod.tsi-dev.otc-service.com/backstage/catalog-ecosystem/contents/blob/main/catalog.yaml
    # templates
    #- type: url
    #  target: https://gitea.eco-preprod.tsi-dev.otc-service.com/backstage/catalog-templates/contents/blob/main/catalog.yaml
    #  rules:
    #    - allow: [Template]
    - type: url
      target: https://github.com/opentelekomcloud-infra/backstage-templates/blob/main/catalog.yaml
      rules:
        - allow: [Template]

kubernetes:
  serviceLocatorMethod:
    type: 'multiTenant'
  clusterLocatorMethods:
    - type: 'config'
      clusters:
        - name: preprod
          authProvider: 'serviceAccount'
          skipTLSVerify: true
          skipMetricsLookup: true
          url: 'https://192.168.150.27:5443'
{{- with secret "secret/data/backstage/k8_infra2" }}
          serviceAccountToken: {{ .Data.data.token }}
{{- end }}

proxy:
  '/quay/api':
    target: 'https://quay.io'
    headers:
      X-Requested-With: 'XMLHttpRequest'

EOT
  perms = "0664"
}
