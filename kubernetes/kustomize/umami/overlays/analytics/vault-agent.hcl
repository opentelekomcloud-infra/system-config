pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra1"
        config = {
            role = "analytics"
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
  destination = "/secrets/analytics-env"
  contents = <<EOT
{{ with secret "secret/data/helpcenter/analytics" -}}
export DATABASE_URL={{ .Data.data.dburl }}
export DATABASE_TYPE="postgresql"
{{- end }}

EOT
  perms = "0664"
}
