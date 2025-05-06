variable "build_path" {
  type    = string
  default = "../build"
}

variable "homelab_vars_file" {
  type    = string
  default = "homelab.vars.yaml"
}

data "local_file" "homelab" {
  filename = "${local.build_path}/${var.homelab_vars_file}"
}

variable "pihole_vars_file" {
  type    = string
  default = "pihole.vars.yaml"
}

data "local_file" "pihole" {
  filename = "${local.build_path}/${var.pihole_vars_file}"
}

variable "registry" {
  type = object({
    ip           = string
    sub_hostname = string
    port         = number
    container_id = number
  })
  default = {
    ip           = "192.168.0.5"
    sub_hostname = "docker"
    port         = 5000
    container_id = 103
  }
}

locals {
  homelab = yamldecode(data.local_file.homelab.content)
  pihole = yamldecode(data.local_file.pihole.content)
  build_path = local.build_path
  registry = merge(
    var.registry,
    {
      hostname     = "${var.registry.sub_hostname}.${local.homelab.hostname}"
      ssh_username = "root"
    }
  )
}
