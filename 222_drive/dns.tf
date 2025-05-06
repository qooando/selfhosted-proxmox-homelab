
resource "pihole_dns_record" "files" {
  domain = local.drive.hostname
  ip     = local.kubernetes.ip
}
