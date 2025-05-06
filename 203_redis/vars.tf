locals {
  build_path      = "../build"
  homelab = yamldecode(file("${local.build_path}/homelab.vars.yaml"))
  pihole = yamldecode(file("${local.build_path}/pihole.vars.yaml"))
  nfs = yamldecode(file("${local.build_path}/nfs.vars.yaml"))
  docker_registry = yamldecode(file("${local.build_path}/docker-registry.vars.yaml"))
  kubernetes = yamldecode(file("${local.build_path}/kubernetes.vars.yaml"))
  kubernetes_init = yamldecode(file("${local.build_path}/kubernetes.init.vars.yaml"))
  redis = {
    default_username = "redis"
  }
}
