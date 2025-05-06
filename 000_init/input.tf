variable "homelab" {
  type = object({
    node_name    = string
    hostname     = string
    api_url      = string
    ssh_username = string
    ssh_password = string
    ip           = string
    gateway      = string
    organization = string
  })
  default = {
    node_name    = "homelab"
    hostname     = "homelab.local"
    api_url      = "https://192.168.0.2:8006/api2/json"
    ssh_username = "root@pam"
    ssh_password = "root123"
    ip           = "192.168.0.2"
    gateway      = "192.168.0.1"
    organization = "homelab"
  }
}

variable "build_path" {
  type    = string
  default = "../build"
}

locals {
  homelab    = var.homelab
  build_path = var.build_path
}
