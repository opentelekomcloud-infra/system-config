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
{{ with secret "secret/data/helpcenter/monitoring/github" -}}
export GITHUB_TOKEN={{ .Data.data.token }}
{{- end }}
{{ with secret "secret/data/helpcenter/monitoring/postgresql" -}}
export DB_HOST={{ .Data.data.host }}
export DB_PORT={{ .Data.data.port }}
export DB_NAME={{ .Data.data.dbname }}
export DB_USER={{ .Data.data.username }}
export DB_PASSWORD={{ .Data.data.password }}
export DB_ORPH={{ .Data.data.dborph }}
export DB_CSV={{ .Data.data.dbname }}
export DB_ZUUL={{ .Data.data.dbzuul }}
{{- end }}
{{ with secret "secret/data/helpcenter/monitoring/gitea" -}}
export GITEA_TOKEN={{ .Data.data.token }}
{{- end }}

EOT
  perms = "0664"
}
