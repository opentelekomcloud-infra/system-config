pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
        config = {
            role = "anubis-service"
            token_path = "/var/run/secrets/tokens/vault-token"
        }
    }
    sink "file" {
        config = {
            path = "/secrets/.vault-token"
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

template {
  destination = "/secrets/ip-whitelist.yaml"
  contents = <<EOT
{{- with secret "secret/data/anubis/ip-whitelist" }}
- name: whitelisted-ips-challenge
  action: CHALLENGE
  expression:
    any:
{{- range $ip := .Data.data.ips }}
      - 'clientIP == "{{ $ip }}"'
{{- end }}
  challenge:
    algorithm: fast
    difficulty: 4
    report_as: 4
{{- end }}
EOT
  perms = "0664"
}
