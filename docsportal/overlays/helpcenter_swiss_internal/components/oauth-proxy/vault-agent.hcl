pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra1"
        config = {
            role = "helpcenter-swiss-internal"
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
redirect_url = "https://docs-swiss-int.otc-service.com/oauth2/callback"
whitelist_domains = [
    "docs-swiss-int.otc-service.com"
]
email_domains = [
    "*"
]
upstreams = [
    "http://document-hosting:8080"
]
session_store_type = "redis"
redis_connection_url = "redis://redis:6379"
cookie_secure = true
cookie_httponly = true
cookie_samesite = "lax"
insecure_oidc_allow_unverified_email = true
{{- with secret "secret/data/helpcenter/swiss/internal/oidc" }}
client_id = "{{ .Data.data.client_id }}"
client_secret = "{{ .Data.data.client_secret }}"
cookie_secret = "{{ .Data.data.cookie_secret }}"
{{- end }}
oidc_issuer_url = "https://keycloak.eco.tsi-dev.otc-service.com/realms/eco"
# Temporarily remove group restriction for testing
# allowed_groups = [
#     "/hc-swiss-internal"
# ]
EOT
  perms = "0664"
}
