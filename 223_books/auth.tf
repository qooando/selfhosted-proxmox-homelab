resource "authentik_application" "calibre" {
  name              = "Calibre"
  slug              = "calibre"
  protocol_provider = local.authentik_config.ldap.provider.id
}
