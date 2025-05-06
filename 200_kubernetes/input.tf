variable "build_path" {
  type    = string
  default = "../build-path"
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

variable "nfs_vars_file" {
  type    = string
  default = "nfs.vars.yaml"
}

data "local_file" "nfs" {
  filename = "${local.build_path}/${var.nfs_vars_file}"
}

variable "docker_registry_vars_file" {
  type    = string
  default = "docker-registry.vars.yaml"
}

data "local_file" "docker-registry" {
  filename = "${local.build_path}/${var.docker_registry_vars_file}"
}

variable "kubernetes" {
  type = object({
    ip           = string
    sub_hostname = string
    vm_id        = number
  })
  default = {
    ip           = "192.168.0.200"
    sub_hostname = "kub"
    vm_id        = 200
  }
}

locals {
  build_path = local.build_path
  homelab = yamldecode(data.local_file.homelab.content)
  pihole = yamldecode(data.local_file.pihole.content)
  nfs = yamldecode(data.local_file.nfs.content)
  docker_registry = yamldecode(data.local_file.docker-registry.content)
  kubernetes = merge(
    var.kubernetes,
    {
      hostname     = "${var.kubernetes.sub_hostname}.${local.homelab.hostname}"
      ssh_username = "root"
    }
  )
}
