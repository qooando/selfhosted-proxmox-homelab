locals {
  registries_yaml = yamlencode({
    mirrors = {
      (local.docker_registry.name) = {
        endpoint = [
          "https://${local.docker_registry.ip}:${local.docker_registry.port}"
        ]
      }
    }
    configs = {
      "docker.io" = {}
      (local.docker_registry.name) = {
        tls = {
          insecure_skip_verify = true
        }
      }
      "${local.docker_registry.ip}:${local.docker_registry.port}" = {
        tls = {
          insecure_skip_verify = true
        }
      }
      # "*" = {
      #   tls = {
      #     insecure_skip_verify = true
      #   }
      # }
    }
  })
}

resource "ssh_resource" "configuration" {
  depends_on = [
    proxmox_virtual_environment_vm.master
  ]
  triggers = {
    hashes = jsonencode([
      sha512(local.registries_yaml),
    ])
  }

  user        = local.kubernetes.ssh_username
  host        = local.kubernetes.ip
  private_key = tls_private_key.ssh.private_key_openssh

  file {
    destination = "/etc/rancher/k3s/registries.yaml"
    content     = local.registries_yaml
  }

  commands = [
    "systemctl restart k3s"
  ]

}
