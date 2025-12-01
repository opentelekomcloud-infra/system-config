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
  destination = "/secrets/oauth2-proxy.cfg"
  contents = <<EOT
http_address = "0.0.0.0:4180"
provider = "oidc"
redirect_url = "https://backstage.eco-preprod.tsi-dev.otc-service.com/oauth2/callback"
email_domains = [
    "*"
]
upstreams = [
    "http://backstage:80"
]
session_store_type = "redis"
redis_connection_url = "redis://redis:6379"
insecure_oidc_allow_unverified_email = true
{{- with secret "secret/data/backstage/oidc" }}
client_id = "{{ .Data.data.client_id }}"
client_secret = "{{ .Data.data.client_secret }}"
cookie_secret = "{{ .Data.data.cookie_secret }}"
{{- end }}
oidc_issuer_url = "https://keycloak.eco-preprod.tsi-dev.otc-service.com/realms/eco"
allowed_groups = [
    "/backstage",
]
EOT
  perms = "0664"
}
