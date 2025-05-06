resource "local_file" "redis_yaml" {
  filename = "${local.build_path}/redis.vars.yaml"
  content = yamlencode({
    default_username  = local.redis.default_username
    default_password  = random_password.default_password.result
    service_host      = local.service.host
    service_port      = local.service.port
    service_host_port = "${local.service.host}:${local.service.port}"
    public_port       = local.service.node_port
  })
}
