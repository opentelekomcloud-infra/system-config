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
  destination = "/vault/secrets/openstack/clouds.yaml"
  source = "/vault/custom/clouds.yaml.hcl"
  perms = "0640"
}

template {
  destination = "/vault/secrets/.kube/config"
  source = "/vault/custom/kube.config.hcl"
  perms = "0640"
}
