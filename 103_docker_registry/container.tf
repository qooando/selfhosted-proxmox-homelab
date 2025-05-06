resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "ssh_password" {
  length  = 32
  special = true
}

resource "macaddress" "eth0_mac" {

}

resource "proxmox_virtual_environment_container" "docker-registry" {
  description = "Docker Registry"
  node_name   = local.homelab.node_name
  vm_id       = local.registry.container_id

  features {}

  # lifecycle {
  #   prevent_destroy = true
  # }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = macaddress.eth0_mac.address
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_file.docker-registry.id
    type             = local.image_os
  }

  disk {
    datastore_id = "local-lvm"
    size         = 10 # gb
  }

  # disk {
  #   datastore_id = "local-lvm"
  #   size         = 1 # zfs ?
  # }

  # mount_point {
  #   # bind mount, *requires* root@pam authentication
  #   volume = "/mnt/bindmounts/shared"
  #   path   = "/mnt/shared"
  # }
  #
  # mount_point {
  #   # volume mount, a new volume will be created by PVE
  #   volume = "local-lvm"
  #   size   = "10G"
  #   path   = "/mnt/volume"
  # }

  initialization {
    hostname = "docker-registry"

    ip_config {
      ipv4 {
        address = "${local.registry.ip}/24"
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