resource "pihole_dns_record" "wireguard" {
  domain = local.wireguard.hostname
  ip     = local.wireguard.ip
}
