locals {
  exports_config_path = "${path.module}/configs/exports"
}

resource "ssh_resource" "configuration" {
  depends_on = [
    proxmox_virtual_environment_container.nfs
  ]

  triggers = {
    hashes = jsonencode([
      filebase64sha512(local.exports_config_path)
    ])
  }

  host        = local.nfs.ip
  user        = local.nfs.ssh_username
  private_key = tls_private_key.ssh.private_key_openssh

  file {
    destination = "/etc/exports"
    content = templatefile(local.exports_config_path, {
      host = local.nfs.ip
    })
  }

  commands = [
    "mkdir -p /srv/share",
    "chmod 777 /srv/share",
    "exportfs -afv",
  ]
}
