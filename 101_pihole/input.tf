variable "build_path" {
  type    = string
  default = "../build"
}

variable "homelab_vars_file" {
  type    = string
  default = "proxmox.vars.yaml"
}

data "local_file" "homelab" {
  filename = "${local.build_path}/${var.homelab_vars_file}"
}

variable "pihole" {
  type = object({
    ip           = string
    sub_hostname = string
    container_id = number
  })
  default = {
    ip           = "192.168.0.101"
    sub_hostname = "pihole"
    container_id = 101
  }
}

locals {
  build_path = local.build_path
  homelab = yamldecode(data.local_file.homelab.content)
  pihole = merge(
    var.pihole,
    {
      ssh_username = "root"
      hostname     = "${var.pihole.sub_hostname}.${local.homelab.hostname}"
    }
  )
}
