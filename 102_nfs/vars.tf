locals {
  build_path = "../build"
  homelab = yamldecode(file("${local.build_path}/homelab.vars.yaml"))
  pihole = yamldecode(file("${local.build_path}/pihole.vars.yaml"))
  nfs = {
    ip           = "192.168.0.102"
    hostname     = "nfs.${local.homelab.hostname}"
    ssh_username = "root"
    container_id = 102
  }
}
