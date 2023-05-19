pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
        config = {
            role = "grafana-docs-monitoring"
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
  destination = "/secrets/gdm-env"
  contents = <<EOT
{{- with secret "secret/data/helpcenter/monitoring/github" -}}
GITHUB_TOKEN={{ .Data.data.token }}
{{- end }}

{{- with secret "secret/data/helpcenter/monitoring/postgresql" -}}
DB_HOST={{ .Data.data.host }}
DB_PORT={{ .Data.data.port }}
DB_NAME={{ .Data.data.dbname }}
DB_USER={{ .Data.data.username }}
DB_PASSWORD={{ .Data.data.password }}
{{- end }}

{{- with secret "secret/data/helpcenter/monitoring/gitea" -}}
GITEA_TOKEN={{ .Data.data.token }}
{{- end }}

EOT
  perms = "0664"
}
