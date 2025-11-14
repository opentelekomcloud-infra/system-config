pid_file = "/home/vault/pidfile"
auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
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
  providers:
    oauth2Proxy: {}
    github:
{{- with secret "secret/data/backstage/github" }}
      development:
        clientId: {{ .Data.data.clientId }}
        clientSecret: {{ .Data.data.clientSecret }}
      production:
        clientId: {{ .Data.data.clientId }}
        clientSecret: {{ .Data.data.clientSecret }}
{{- end }}
{{- with secret "secret/data/backstage/gitea" }}
    gitea:
      development:
        metadataUrl: https://gitea.eco-preprod.tsi-dev.otc-service.com/.well-known/openid-configuration
        authorizationUrl: https://gitea.eco-preprod.tsi-dev.otc-service.com/login/oauth/authorize
        tokenUrl: https://gitea.eco-preprod.tsi-dev.otc-service.com/login/oauth/access_token
        clientId: {{ .Data.data.clientId }}
        clientSecret: {{ .Data.data.clientSecret }}
{{- end }}

catalog:
{{- with secret "secret/data/backstage/oidc" }}
  providers:
    keycloakOrg:
      default:
        baseUrl: https://keycloak.eco-preprod.tsi-dev.otc-service.com/
        loginRealm: {{ .Data.data.realm }}
        realm: {{ .Data.data.realm }}
        clientId: {{ .Data.data.client_id }}
        clientSecret: {{ .Data.data.client_secret }}
{{- end }}
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

integrations:
  gitea:
{{- with secret "secret/data/backstage/gitea" }}
    - host: gitea.eco-preprod.tsi-dev.otc-service.com
      password: {{ .Data.data.token }}
{{- end }}
  github:
    - host: github.com
      apps:
{{- with secret "secret/data/backstage/github" }}
        - appId: {{ .Data.data.appId }}
          clientId: {{ .Data.data.clientId }}
          clientSecret: {{ .Data.data.clientSecret }}
          webhookSecret: {{ .Data.data.webhookSecret}}
          privateKey: |
{{ .Data.data.privateKey | indent 12 }}
{{- end }}

kubernetes:
  serviceLocatorMethod:
    type: 'multiTenant'
  clusterLocatorMethods:
    - type: 'config'
      clusters:
        - name: otcinfra2
          authProvider: 'serviceAccount'
          skipTLSVerify: true
          skipMetricsLookup: true
          url: 'https://192.168.171.211:5443'
{{- with secret "secret/data/backstage/k8_infra2" }}
          serviceAccountToken: {{ .Data.data.token }}
{{- end }}

proxy:
  '/grafana/api':
    target: https://dashboard.tsi-dev.otc-service.com
    headers:
{{- with secret "secret/data/backstage/grafana" }}
      Authorization: "Bearer {{ .Data.data.token }}"
{{- end }}
  '/dependencytrack':
    target: https://dependencytrack.eco-preprod.tsi-dev.otc-service.com
    allowedMethods: ['GET']
    headers:
{{- with secret "secret/data/backstage/dependencytrack" }}
      X-Api-Key: "{{ .Data.data.token }}"
{{- end }}
  '/quay/api':
    target: 'https://quay.io'
    headers:
      X-Requested-With: 'XMLHttpRequest'

EOT
  perms = "0664"
}
