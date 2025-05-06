resource "pihole_dns_record" "gitea" {
  domain = local.gitea.hostname
  ip     = local.kubernetes.ip
}
