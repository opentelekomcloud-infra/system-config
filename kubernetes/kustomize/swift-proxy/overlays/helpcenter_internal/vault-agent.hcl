pid_file = "/home/vault/pidfile"
auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra1"
        config = {
            role = "swift-proxy-int"
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
  destination = "/secrets/clouds.yaml"
  contents = <<EOT
clouds:
  logs:
{{- with secret "openstack/static-creds/cloud_448_de_hc_int" }}
{{ .Data | toYAML | indent 4 }}
{{- end }}
EOT
  perms = "0664"
}
