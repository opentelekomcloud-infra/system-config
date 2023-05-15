pid_file = "/home/vault/pidfile"
auto_auth {
    method "kubernetes" {
        mount_path = "auth/kubernetes_otcinfra2"
        config = {
            role = "backstage"
            token_path = "/var/run/secrets/tokens/vault-token"
        }
    }
    sink "file" {
        config = {
            path = "/home/vault/.vault-token"
        }
    }
}

path "secret/helpcenter/monitoring/github" {
  capabilities = ["read"]
}

path "secret/helpcenter/monitoring/gitea" {
  capabilities = ["read"]
}
