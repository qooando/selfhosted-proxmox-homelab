resource "local_file" "gitea_yaml" {
  filename = "${local.build_path}/gitea.vars.yaml"
  content = yamlencode({
    hostname           = local.gitea.hostname
    url                = "https://${local.gitea.hostname}"
    db                 = postgresql_database.gitea.name
    db_username        = local.postgres.default_user
    db_password        = local.postgres.default_password
    admin_username     = local.gitea.admin_username
    admin_password     = random_password.admin-password.result
    registration_token = random_password.registration-token.result
    service_host_port  = "gitea-http.${kubernetes_namespace.gitea.metadata.0.name}:3000"
  })
}