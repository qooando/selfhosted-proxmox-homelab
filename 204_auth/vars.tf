locals {
  build_path = "../build"
  homelab = yamldecode(file("${local.build_path}/homelab.vars.yaml"))
  pihole = yamldecode(file("${local.build_path}/pihole.vars.yaml"))
  nfs = yamldecode(file("${local.build_path}/nfs.vars.yaml"))
  docker_registry = yamldecode(file("${local.build_path}/docker-registry.vars.yaml"))
  kubernetes = yamldecode(file("${local.build_path}/kubernetes.vars.yaml"))
  kubernetes_init = yamldecode(file("${local.build_path}/kubernetes.init.vars.yaml"))
  postgres = yamldecode(file("${local.build_path}/postgres.vars.yaml"))
  redis = yamldecode(file("${local.build_path}/redis.vars.yaml"))
  authentik = {
    hostname          = "auth.${local.homelab.hostname}"
    manual_auth_token = "CB7G6Z6s11wgBnl0RqGe6sPHcCHrwhsLqq87yLlhIKfpeHv6jSbQg60L5vMc"
  }
}
