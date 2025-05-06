locals {
  build_path = "../build"
  homelab = yamldecode(file("${local.build_path}/homelab.vars.yaml"))
  pihole = yamldecode(file("${local.build_path}/pihole.vars.yaml"))
  nfs = yamldecode(file("${local.build_path}/nfs.vars.yaml"))
  docker_registry = yamldecode(file("${local.build_path}/docker-registry.vars.yaml"))
  kubernetes = yamldecode(file("${local.build_path}/kubernetes.vars.yaml"))
  traefik_dashboard = {
    hostnames = [
      "traefik.${local.homelab.hostname}"
    ]
  }
  traefik = {
    ssh_port       = 2222
    ssh_entrypoint = "ssh"
  }
}
