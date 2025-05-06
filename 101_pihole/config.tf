locals {
  pihole_toml_content = templatefile("${path.module}/configs/pihole.toml", {
    host = local.pihole.hostname
    hosts = jsonencode([
      "${local.homelab.ip} ${local.homelab.gui_hostname}",
      "${local.pihole.ip} ${local.pihole.hostname}"
    ])
  })
}

resource "random_password" "webserver_api_password" {
  length  = 32
  special = true
}

resource "ssh_resource" "configuration" {
  depends_on = [
    proxmox_virtual_environment_container.pihole
  ]

  triggers = {
    hashes = jsonencode([
      sha512(local.pihole_toml_content),
      random_password.webserver_api_password.result,
      tls_locally_signed_cert.webserver.cert_request_pem
    ])
  }

  host        = local.pihole.ip
  user        = local.pihole.ssh_username
  private_key = tls_private_key.ssh.private_key_pem
  timeout     = "1m"

  file {
    destination = "/etc/pihole/pihole.toml"
    content     = local.pihole_toml_content
  }

  file {
    destination = "/etc/pihole/tls.pem"
    content = join("", [
      tls_locally_signed_cert.webserver.cert_pem,
      tls_cert_request.webserver.private_key_pem
    ])
  }

  file {
    destination = "/etc/pihole/tls_ca.crt"
    content     = tls_locally_signed_cert.webserver.ca_cert_pem
  }

  commands = [
    "pihole setpassword '${random_password.webserver_api_password.result}'",
    "reboot"
  ]
}