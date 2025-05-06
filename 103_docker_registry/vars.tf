locals {
  build_path = "../build"
  homelab = yamldecode(file("${local.build_path}/homelab.vars.yaml"))
  pihole = yamldecode(file("${local.build_path}/pihole.vars.yaml"))
  registry = {
    ip           = "192.168.0.103"
    hostname     = "docker.${local.homelab.hostname}"
    ssh_username = "root"
    port         = 5000
    container_id = 103
  }
}
