pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
        config = {
            role = "giji"
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
  destination = "/secrets/giji-env"
  contents = <<EOT
{{ with secret "secret/data/github/otcbot" -}}
export GITHUB_BOT_TOKEN={{ .Data.data.otcbot_token }}
{{- end }}
{{ with secret "secret/data/helpcenter/monitoring/postgresql" -}}
export DB_HOST={{ .Data.data.host }}
export DB_PORT={{ .Data.data.port }}
export DB_NAME={{ .Data.data.dbname }}
export DB_USER={{ .Data.data.username }}
export DB_PASSWORD={{ .Data.data.password }}
{{- end }}
{{ with secret "secret/data/jira/autoecobot" -}}
export OTC_BOT_API={{ .Data.data.jira_api_key }}
{{- end }}

EOT
  perms = "0664"
}
