terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    macaddress = {
      source = "ivoronin/macaddress"
    }
    remote = {
      source = "tmscer/remote"
    }
    ssh = {
      source = "loafoe/ssh"
    }
    pihole = {
      source = "iolave/pihole"
      version = "0.2.2-beta.2"
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

provider "pihole" {
  url      = local.pihole.api_url
  password = local.pihole.web_password
  ca_file  = local.pihole.web_cert_file
}
