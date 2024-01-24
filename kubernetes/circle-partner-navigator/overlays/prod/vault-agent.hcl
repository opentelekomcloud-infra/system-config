pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
        config = {
            role = "cpn"
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
  destination = "/secrets/cpn-env"
  contents = <<EOT
{{ with secret "secret/data/cpn" -}}
export DATABASE_CLIENT={{ .Data.data.client }}
export DATABASE_HOST={{ .Data.data.dbhost }}
export DATABASE_PORT={{ .Data.data.port }}
export DATABASE_NAME={{ .Data.data.dbname }}
export DATABASE_USERNAME={{ .Data.data.username }}
export DATABASE_PASSWORD={{ .Data.data.password }}
export JWT_SECRET={{ .Data.data.jwssecret }}
export ADMIN_JWT_SECRET={{ .Data.data.adminjwssecret }}
export APP_KEYS={{ .Data.data.appkeys }}
export API_TOKEN_SALT={{ .Data.data.apitokensalt }}
export TRANSFER_TOKEN_SALT={{ .Data.data.transfertokensalt }}
export HOST={{ .Data.data.host }}
export PORT={{ .Data.data.port }}
{{- end }}

EOT
  perms = "0664"
}
