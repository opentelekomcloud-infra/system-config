pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
        config = {
            role = "gitea"
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

# PostgreSQL superuser password
template {
    destination = "/secrets/postgres-superuser-passwd"
    contents = <<EOT
{{- with secret "secret/data/gitea/config" -}}
{{ .Data.data.pg_postgres_password }}
{{- end }}
EOT
    perms = "0664"
}
