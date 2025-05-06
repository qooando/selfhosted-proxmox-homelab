resource "pihole_dns_record" "dns" {
  domain = local.authentik.hostname
  ip     = local.kubernetes.ip
}