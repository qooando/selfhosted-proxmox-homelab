locals {
  build_path = "../build"
  homelab = yamldecode(file("${local.build_path}/homelab.vars.yaml"))
  pihole = merge(
    {
      ip           = "192.168.0.101"
      sub_hostname = "pihole"
      ssh_username = "root"
      hostname     = "pihole.${local.homelab.hostname}"
      container_id = 101
    }
  )
}
