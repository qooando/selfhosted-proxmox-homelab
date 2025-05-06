locals {
  config_yml_path = "${path.module}/configs/config.yml"
  conf_path       = "${path.module}/configs/docker-registry.conf"
}

resource "ssh_resource" "configuration" {
  depends_on = [
    proxmox_virtual_environment_container.docker-registry
  ]
  triggers = {
    hashes = jsonencode([
      filesha512(local.conf_path),
      filesha512(local.config_yml_path),
      sha512(tls_locally_signed_cert.docker-registry.cert_pem)
    ])
  }

  user        = local.registry.ssh_username
  host        = local.registry.ip
  private_key = tls_private_key.ssh.private_key_openssh

  file {
    content = templatefile(local.conf_path, {})
    destination = "/etc/conf.d/docker-registry"
  }

  file {
    content = templatefile(local.config_yml_path, {})
    destination = "/etc/docker-registry/config.yml"
  }

  file {
    content     = tls_locally_signed_cert.docker-registry.cert_pem
    destination = "/etc/docker-registry/docker.crt"
  }

  file {
    content     = tls_private_key.docker-registry.private_key_pem
    destination = "/etc/docker-registry/docker.key"
  }

  commands = [
    "reboot"
  ]

}
