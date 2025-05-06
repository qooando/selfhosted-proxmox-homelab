resource "local_file" "immich_yaml" {
  filename = "${local.build_path}/immich.vars.yaml"
  content = yamlencode({
    hostnames      = local.immich.hostnames
    db             = postgresql_database.immich.name
    db_username    = local.postgres.default_user
    db_password    = local.postgres.default_password
    admin_username = local.immich.admin_username
    admin_password = random_password.admin-password.result
  })
}
