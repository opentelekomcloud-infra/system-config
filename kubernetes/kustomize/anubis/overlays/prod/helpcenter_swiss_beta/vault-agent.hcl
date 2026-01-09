pid_file = "/home/vault/pidfile"

auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra1"
        config = {
            role = "anubis-vault-auth"
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

template {
  destination = "/secrets/ip-whitelist.yaml"
  contents = <<EOT
{{- with secret "secret/data/anubis/ip-whitelist" }}
- name: whitelisted-ips-challenge
  action: CHALLENGE
  remote_addresses:
{{- range $cidr := .Data.data.ips }}
      - {{ $cidr }}
{{- end }}
  challenge:
    algorithm: fast
    difficulty: 4
    report_as: 4
{{- end }}
EOT
  perms = "0664"
}

