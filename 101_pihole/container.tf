resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "ssh_password" {
  length  = 32
  special = true
}

resource "macaddress" "eth0_mac" {}

resource "proxmox_virtual_environment_container" "pihole" {
  description = "Pi-hole dns server"
  node_name   = local.homelab.node_name
  vm_id       = local.pihole.container_id

  features {}

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = macaddress.eth0_mac.address
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_file.image.id
    type             = local.image_os
  }

  disk {
    datastore_id = "local-lvm"
    size         = 1
  }

  initialization {
    hostname = "pihiole"

    ip_config {
      ipv4 {
        address = "${local.pihole.ip}/24"
        gateway = local.homelab.gateway
      }
    }

    user_account {
      keys = [
        trimspace(tls_private_key.ssh.public_key_openssh)
      ]
      password = random_password.ssh_password.result
    }
  }

}