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
  destination = "/secrets/emg-env"
  contents = <<EOT
{{ with secret "secret/data/cpn/express-mail-gateway" -}}
SMTP_USER={{ .Data.data.user }}
SMTP_PASS={{ .Data.data.pass }}
SMTP_DOMAIN={{ .Data.data.domain }}
SMTP_PORT={{ .Data.data.port }}
MAIL_RECIPIENT={{ .Data.data.recipient }}
MCAPTCHA_SECRET={{ .Data.data.mcaptcha_secret }}
{{- end }}

EOT
  perms = "0664"
}
