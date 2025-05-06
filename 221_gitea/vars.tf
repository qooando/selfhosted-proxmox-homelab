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
  authentik = yamldecode(file("${local.build_path}/authentik.vars.yaml"))
  gitea = {
    hostname       = "git.${local.homelab.hostname}"
    admin_username = "admin"
    admin_email    = "admin@example.com"
    ssh_port       = 2222
    db_name        = "gitea"
    users = {
      user1 = {
        username = "user1"
        email    = "user1@example.com"
      }
    }
  }
}
