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

cache {
    use_auto_auth_token = true
}

template {
  destination = "/secrets/app-config.production.yaml"
  contents = <<EOT
app:
  baseUrl: https://backstage.eco.tsi-dev.otc-service.com

backend:
  baseUrl: https://backstage.eco.tsi-dev.otc-service.com
  listen:
    port: 7007
  cors:
    origin: https://backstage.eco.tsi-dev.otc-service.com

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

catalog:
{{- with secret "secret/data/backstage/oidc" }}
  providers:
    keycloakOrg:
      default:
        baseUrl: https://keycloak.eco.tsi-dev.otc-service.com/
        loginRealm: {{ .Data.data.realm }}
        realm: {{ .Data.data.realm }}
        clientId: {{ .Data.data.client_id }}
        clientSecret: {{ .Data.data.client_secret }}
{{- end }}
  readonly: true
  rules:
    - allow: [Component, System, API, Resource, Location, Group, User]
  locations:
    # General
    - type: url
      target: https://gitea.eco.tsi-dev.otc-service.com/backstage/catalog/contents/blob/main/otc-catalog.yaml
      rules:
        - allow: [Domain, Group, User, Location, Component, Resource, API, System]
    # Compute
    - type: url
      target: https://gitea.eco.tsi-dev.otc-service.com/backstage/catalog-compute/contents/blob/main/catalog.yaml
    # Ecosystem
    - type: url
      target: https://gitea.eco.tsi-dev.otc-service.com/backstage/catalog-ecosystem/contents/blob/main/catalog.yaml


integrations:
  gitea:
{{- with secret "secret/data/backstage/gitea" }}
    - host: gitea.eco.tsi-dev.otc-service.com
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
    target: https://dependencytrack.eco.tsi-dev.otc-service.com
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
