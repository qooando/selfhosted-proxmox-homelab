variable "build_path" {
  type    = string
  default = "../build"
}

variable "homelab_vars_file" {
  type    = string
  default = "homelab.vars.yaml"
}

variable "pihole_vars_file" {
  type    = string
  default = "pihole.vars.yaml"
}

variable "nfs" {
  type = object({
    ip = string
    sub_hostname = string
    container_id = number
  })
  default = {
    ip           = "192.168.0.102"
    sub_hostname = "nfs"
    container_id = 102
  }
}

data "local_file" "homelab" {
  filename = "${local.build_path}/${var.homelab_vars_file}"
}

data "local_file" "pihole" {
  filename = "${local.build_path}/${var.pihole_vars_file}"
}

locals {
  build_path = build_path
  homelab = yamldecode(data.local_file.homelab.content)
  pihole = yamldecode(data.local_file.pihole.content)
  nfs = merge(
    var.nfs,
    {
      hostname     = "${var.nfs.sub_hostname}.${local.homelab.hostname}"
      ssh_username = "root"
    }
  )
}
