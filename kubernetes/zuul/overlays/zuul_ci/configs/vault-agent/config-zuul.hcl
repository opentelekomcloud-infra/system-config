pid_file = "/home/vault/.pid"
"auto_auth" = {
    "method" = {
        "mount_path" = "auth/kubernetes_otcci"
        "config" = {
          "role" = "zuul"
        }
        "type" = "kubernetes"
      }
    sink "file" {
        config = {
            path = "/home/vault/.token"
        }
    }
}

cache {
    use_auto_auth_token = true
}

template {
  destination = "/vault/secrets/connections/github.key"
  contents = <<EOT
{{- with secret "secret/zuul/connections/github" }}{{ .Data.data.app_key }}{{ end }}
EOT
  perms = "0600"
}
template {
  destination = "/vault/secrets/connections/gitlab.key"
  contents = <<EOT
{{ with secret "secret/zuul/connections/gitlab" }}{{ .Data.data.ssh_key }}{{ end }}
EOT
  perms = "0600"
}
template {
  destination = "/vault/secrets/connections/gitea.key"
  contents = <<EOT
{{ with secret "secret/zuul/connections/gitea" }}{{ .Data.data.ssh_key }}{{ end }}
EOT
  perms = "0600"
}

template {
  destination = "/vault/secrets/zuul.conf"
  source = "/vault/custom/zuul.conf.hcl"
  perms = "0644"
  # exec = { command = "sh -c '{ if [ -f /secrets/config.check ]; then kubectl -n zuul-ci rollout restart statefulset zuul-executor; else touch /secrets/config.check; fi }'", timeout = "30s" }
}
template {
  destination = "/vault/secrets/sshkey"
  contents = <<EOT
{{- with secret "secret/zuul/sshkey" }}{{ .Data.data.private_key }}{{ end }}
EOT
  perms = "0600"
}
