resource "local_file" "vars_yaml" {
  filename = "${local.build_path}/calibre.vars.yaml"
  content = yamlencode({
    hostname  = local.books.hostname
    node_port = kubernetes_service.calibre-workaround.spec.0.port.0.node_port
    ldap = {
      server_hostname              = local.authentik_config.ldap.service_host
      server_port                  = local.authentik_config.ldap.service_port
      encryption                   = null
      authentication               = "simple"
      administrator_username       = local.authentik_config.ldap.service_user.login
      administrator_password       = local.authentik_config.ldap.service_user.password
      distinguished_name           = local.authentik_config.ldap.base_dn
      base_dn                      = local.authentik_config.ldap.base_dn
      DN                           = local.authentik_config.ldap.base_dn
      user_object_filter           = "(&(objectclass=user)(cn=%s))"
      is_openldap                  = true
      group_object_filter          = "(&(objectclass=group)(cn=%s))"
      group_name                   = local.authentik_config.ldap.users_group
      group_member_field           = "member"
      member_user_filter_detection = "autodetect"
    }
  })
}