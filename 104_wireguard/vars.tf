locals {
  build_path     = "../build"
  homelab = yamldecode(file("${local.build_path}/homelab.vars.yaml"))
  pihole = yamldecode(file("${local.build_path}/pihole.vars.yaml"))
  build_vpn_path = "${local.build_path}/wireguard-vpn"
  wireguard = {
    ip                  = "192.168.0.104"
    container_id        = 104
    udp_port            = 989
    hostname            = "wireguard.${local.homelab.hostname}"
    ssh_username        = "root"
    public_gateway_host = "yourhost.ddns.net" # ddns with no-ip
  }
}
