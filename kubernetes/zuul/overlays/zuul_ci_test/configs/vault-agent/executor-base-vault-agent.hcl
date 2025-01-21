pid_file = "/home/vault/.pid"

"auto_auth" = {
    "method" = {
        "mount_path" = "auth/kubernetes_otcci"
        "config" = {
          # Here we explicitly request zuul-base role which gives access to 
          # only certain policies
          "role" = "zuul-base"
        }
        "type" = "kubernetes"
      }
    sink "file" {
        config = {
            # Write token into the file zuul executor reads
            path = "/var/run/zuul/trusted-ro/zuul-base-vault-token"
        }
    }
}

cache {
    use_auto_auth_token = true
}

# Vault agent requires at least one template or listener is present. Add a socket
listener "unix" {
    address = "/home/vault/vault_agent.socket"
    tls_disable = true
}
