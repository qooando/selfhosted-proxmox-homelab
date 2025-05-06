resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "ssh_password" {
  length  = 32
  special = true
}

resource "macaddress" "eth0_mac" {}
resource "macaddress" "wg0_mac" {}

resource "proxmox_virtual_environment_container" "wireguard" {
  description = "Wireguard"
  node_name   = local.homelab.node_name
  vm_id       = local.wireguard.container_id

  features {
    keyctl  = true
    nesting = true
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = macaddress.eth0_mac.address
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_file.wireguard.id
    type             = local.image_os
  }

  disk {
    datastore_id = "local-lvm"
    size         = 1 # gb
  }

  cpu {
    cores = 2
    units = 1
  }

  initialization {
    hostname = "wireguard"

    ip_config {
      ipv4 {
        address = "${local.wireguard.ip}/24"
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
