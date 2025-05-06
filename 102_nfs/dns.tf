resource "pihole_dns_record" "nfs" {
  domain = local.nfs.hostname
  ip     = local.nfs.ip
}
