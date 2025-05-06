resource "local_file" "vars_yaml" {
  filename = "${local.build_path}/authentik_config.vars.yaml"
  content = yamlencode({
    ldap = {
      service_host = "ak-outpost-ldap.${local.authentik.namespace}"
      service_port = 389
      ldap_url     = "ldap://ak-outpost-ldap.${local.authentik.namespace}:389"
      provider = tomap(authentik_provider_ldap.ldap)
      base_dn      = local.base_dn
      service_user = {
        login    = "cn=${authentik_user.ldap-automation.username},ou=users,${local.base_dn}"
        username = authentik_user.ldap-automation.username
        password = authentik_user.ldap-automation.password
      }
      users_group = authentik_group.ldap.name
    }
  })
}

resource "local_file" "users_yaml" {
  filename = "${local.build_path}/authentik_users.vars.yaml"
  content = yamlencode(local.users_with_pass)
}
