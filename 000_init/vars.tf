locals {
  build_path = "../build"
  homelab = {
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
