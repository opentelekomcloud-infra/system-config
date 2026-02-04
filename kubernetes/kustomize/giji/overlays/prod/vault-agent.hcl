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

api_proxy {
    use_auto_auth_token = "force"
    enforce_consistency = "always"
}

listener "tcp" {
    address = "127.0.0.1:8100"
    tls_disable = true
}

# Jira certificate (PEM)
template {
    destination = "/secrets/jira-cert.pem"
    contents = <<EOT
{{ with secret "secret/data/jira/autoecobot" -}}
{{ .Data.data.jira_pem }}
{{- end }}
EOT
    perms = "0600"
}

# Jira private key
template {
    destination = "/secrets/jira-key.pem"
    contents = <<EOT
{{ with secret "secret/data/jira/autoecobot" -}}
{{ .Data.data.jira_key }}
{{- end }}
EOT
    perms = "0600"
}

# Environment variables
template {
    destination = "/secrets/giji-env"
    contents = <<EOT
{{ with secret "secret/data/github/otcbot" -}}
export GITHUB_TOKEN={{ .Data.data.otcbot_giji_token }}
{{- end }}
{{ with secret "secret/data/helpcenter/monitoring/github" -}}
export GITHUB_API_URL={{ .Data.data.github_api_url }}
export GITHUB_ORGS={{ .Data.data.github_orgs }}
{{- end }}

{{ with secret "secret/data/helpcenter/monitoring/postgresql" -}}
export DB_HOST={{ .Data.data.host }}
export DB_PORT={{ .Data.data.port }}
export DB_CSV={{ .Data.data.dbname }}
export DB_USER={{ .Data.data.username }}
export DB_PASSWORD={{ .Data.data.password }}
{{- end }}

{{ with secret "secret/data/gitea" -}}
export BASE_GITEA_URL={{ .Data.data.base_url }}
{{- end }}

{{ with secret "secret/data/jira/autoecobot" -}}
export JIRA_API_URL={{ .Data.data.jira_api_url }}
export JIRA_TOKEN={{ .Data.data.jira_api_key }}
export JIRA_CERT_PATH={{ .Data.data.jira_pem }}
export JIRA_KEY_PATH={{ .Data.data.jira_key }}
{{- end }}

{{ with secret "secret/data/giji/master_component" -}}
export DEH="{{ .Data.data.dedicated-host }}"
export ASG="{{ .Data.data.auto-scaling }}"
export ECS="{{ .Data.data.elastic-cloud-server }}"
export IMS="{{ .Data.data.image-management-service }}"
export BMS="{{ .Data.data.bare-metal-server }}"
export RDS="{{ .Data.data.relational-database-service }}"
export OPENGAUSS="{{ .Data.data.gaussdb-opengauss }}"
export GEMINIDB="{{ .Data.data.geminidb }}"
export MYSQL="{{ .Data.data.gaussdb-mysql }}"
export DRS="{{ .Data.data.data-replication-service }}"
export DAS="{{ .Data.data.data-admin-service }}"
export DDM="{{ .Data.data.distributed-database-middleware }}"
export DDS="{{ .Data.data.document-database-service }}"
{{ end }}
{{ with secret "secret/data/giji/config" -}}
export JIRA_PROJECT_KEY="{{ .Data.data.jira_project_key }}"
export TARGET_SQUADS="{{ .Data.data.target_squads }}"
export IMPORTED_LABEL="{{ .Data.data.imported_label }}"
export JIRA_ISSUE_TYPE="{{ .Data.data.jira_issue_type }}"
{{ end }}

EOT
    perms = "0600"
}
