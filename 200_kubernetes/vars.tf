locals {
  build_path = "../build"
  homelab = yamldecode(file("${local.build_path}/homelab.vars.yaml"))
  pihole = yamldecode(file("${local.build_path}/pihole.vars.yaml"))
  nfs = yamldecode(file("${local.build_path}/nfs.vars.yaml"))
  docker_registry = yamldecode(file("${local.build_path}/docker-registry.vars.yaml"))
  kubernetes = {
    ip           = "192.168.0.200"
    vm_id        = 200
    hostname     = "kub.${local.homelab.hostname}"
    ssh_username = "root"
  }
}
