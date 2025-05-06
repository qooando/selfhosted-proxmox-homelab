resource "local_file" "postgres_yaml" {
  filename = "${local.build_path}/postgres.vars.yaml"
  content = yamlencode({
    # hostname          = local.postgres.hostname
    default_user      = local.postgres.default_user
    default_password  = random_password.default-password.result
    default_db        = local.postgres.default_db
    service_host      = local.service.host
    service_port      = local.service.port
    service_host_port = "${local.service.host}:${local.service.port}"
    public_port       = local.service.node_port
  })
}