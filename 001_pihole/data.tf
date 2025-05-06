variable "build_path" {
  type    = string
  default = "../build"
}

variable "homelab_vars_file" {
  type    = string
  default = "proxmox.vars.yaml"
}

variable "pihole" {
  type = object({
    ip           = string
    sub_hostname = string
    container_id = number
  })
  default = {
    ip           = "192.168.0.3"
    sub_hostname = "pihole"
    container_id = 101
  }
}
data "local_file" "homelab" {
  filename = "${local.build_path}/${var.homelab_vars_file}"
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
