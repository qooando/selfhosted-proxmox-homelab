locals {
  dockerfile_path     = "${path.module}/image/Dockerfile"
  docker_postgres_tag = "${local.docker_registry.name}/postgres:17-custom"
}

module "postgres_image" {
  source        = "../modules/buildah"
  dockerfile    = local.dockerfile_path
  tag           = local.docker_postgres_tag
  keep_locally  = true
  keep_remotely = false
}