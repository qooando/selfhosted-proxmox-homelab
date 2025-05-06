resource "pihole_dns_record" "docker-registry" {
  domain = local.registry.hostname
  ip     = local.registry.ip
}
