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
{{- end }}

{{ with secret "secret/data/giji/master_component" -}}
export DEH={{ index .Data.data "dedicated-host" }}
export ASG={{ index .Data.data "auto-scaling" }}
export ECS={{ index .Data.data "elastic-cloud-server" }}
export IMS={{ index .Data.data "image-management-service" }}
export BMS={{ index .Data.data "bare-metal-server" }}
export RDS={{ index .Data.data "relational-database-service" }}
export OPENGAUSS={{ index .Data.data "gaussdb-opengauss" }}
export GEMINIDB={{ index .Data.data "geminidb" }}
export MYSQL={{ index .Data.data "gaussdb-mysql" }}
export DRS={{ index .Data.data "data-replication-service" }}
export DAS={{ index .Data.data "data-admin-service" }}
export DDM={{ index .Data.data "distributed-database-middleware" }}
export DDS={{ index .Data.data "document-database-service" }}
{{- end }}

{{ with secret "secret/data/giji/config" -}}
export JIRA_PROJECT_KEY={{  .Data.data.jira_project_key }}
export TARGET_SQUADS={{  .Data.data.target_squads }}
export IMPORTED_LABEL={{  .Data.data.imported_label }}
export JIRA_ISSUE_TYPE={{  .Data.data.jira_issue_tag }}
export QA={{  .Data.data.QA }}
export UAT={{  .Data.data.UAT }}
export SEC={{  .Data.data.SEC }}
export master_component={{  .Data.data.master_component }}
export users_impact={{  .Data.data.users_impact }}
export affected_locations={{  .Data.data.affected_locations }}
export test_category={{  .Data.data.test_category }}
export priority={{  .Data.data.priority }}
export bug_type={{  .Data.data.bug_type }}
export affected_areas={{  .Data.data.affected_areas }}
export estimated_effort={{  .Data.data.estimated_effort }}
export tier={{  .Data.data.tier }}
export pays_into={{  .Data.data.pays_into }}
export description={{  .Data.data.description }}
{{- end }}
export JIRA_CERT_PATH=/secrets/jira-cert.pem
export JIRA_KEY_PATH=/secrets/jira-key.pem
EOT
    perms = "0600"
}
