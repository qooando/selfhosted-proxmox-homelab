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

variable "wireguard" {
  type = object({
    ip                  = string
    sub_hostname        = string
    container_id        = number
    udp_port            = number
    public_gateway_host = "yourhost.ddns.net" # ddns with no-ip
  })
}

locals {
  build_path     = var.build_path
  build_vpn_path = "${local.build_path}/wireguard-vpn"
  homelab = yamldecode(data.local_file.homelab.content)
  pihole = yamldecode(data.local_file.pihole.content)
  wireguard = merge(
    var.wireguard,
    {
      hostname     = "${var.wireguard.sub_hostname}.${local.homelab.hostname}"
      ssh_username = "root"
    }
  )
}
