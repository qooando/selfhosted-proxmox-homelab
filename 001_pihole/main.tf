terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    macaddress = {
      source = "ivoronin/macaddress"
    }
    ssh = {
      source = "loafoe/ssh"
    }
  }
}

provider "proxmox" {
  endpoint = local.homelab.api_url
  insecure = true
  username = local.homelab.ssh_username
  password = local.homelab.ssh_password
}

provider "ssh" {}