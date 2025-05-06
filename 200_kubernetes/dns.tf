resource "pihole_dns_record" "kubernetes" {
  domain = local.kubernetes.hostname
  ip     = local.kubernetes.ip
}
