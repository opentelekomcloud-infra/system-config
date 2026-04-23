pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
        config = {
            role = "openapi-validator"
            token_path = "/var/run/secrets/tokens/vault-token"
        }
    }
    sink "file" {
        config = {
            path = "/home/vault/.vault-token"
        }
    }
}

template {
  destination = "/secrets/openapi-validator-env"
  contents = <<EOT
{{ with secret "secret/data/openapi-validator-dev" -}}
export GITEA_TOKEN={{ .Data.data.gitea_token }}
{{- end }}

EOT
  perms = "0664"
}
