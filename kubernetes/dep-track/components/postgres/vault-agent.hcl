pid_file = "/home/vault/pidfile"
auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
        config = {
            role = "dependencytrack"
            token_path = "/var/run/secrets/tokens/vault-token"
        }
    }
    sink "file" {
        config = {
            path = "/home/vault/.vault-token"
        }
    }
}

cache {
    use_auto_auth_token = true
}

template {
  destination = "/secrets/postgres-passwd"
  contents = <<EOT
{{- with secret "secret/data/dependencytrack/db" }}
{{ .Data.data.password }}
{{- end }}
EOT
  perms = "0664"
}
