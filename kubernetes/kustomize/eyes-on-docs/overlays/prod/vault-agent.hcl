pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
        config = {
            role = "eyes-on-docs"
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
export GITHUB_FALLBACK_TOKEN={{ .Data.data.fallback_token }}
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
{{ with secret "secret/data/helpcenter/monitoring/zulip" -}}
export OTC_BOT_API={{ .Data.data.token }}
export ZULIP_EMAIL={{ .Data.data.email }}
export ZULIP_SITE={{ .Data.data.site }}
{{- end }}
{{ with secret "secret/data/helpcenter/monitoring/gitea" -}}
export GITEA_TOKEN={{ .Data.data.token }}
{{- end }}
{{ with secret "secret/data/gitea/config" -}}
export BASE_GITEA_URL={{ .Data.data.gitea_address }}
{{- end }}
{{ with secret "secret/data/eyes-on-docs/dashboards" -}}
export OPEN_PRS_URL={{ .Data.data.open_prs }}
export OPEN_ISSUES_URL={{ .Data.data.open_issues }}
export LAST_DOCS_COMMIT_URL={{ .Data.data.last_docs_commit }}
export OPEN_ISSUES_ECO_URL={{ .Data.data.open_issues_eco }}
export REQUESTED_CHANGES_URL={{ .Data.data.requested_changes }}
export VENDOR_ANALYSED_LABELED_URL={{ .Data.data.vendor_analysed_labeled }}
export VENDOR_TO_OTC_RST_URL={{ .Data.data.vendor_to_otc_rst }}
export FILES_LINES_URL={{ .Data.data.files_lines }}
export MISSING_CHILD_PRS_URL={{ .Data.data.missing_child_prs }}
{{- end }}

EOT
  perms = "0664"
}
