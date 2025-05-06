resource "pihole_dns_record" "calibre" {
  domain = local.books.hostname
  ip     = local.kubernetes.ip
}
