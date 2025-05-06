locals {
  dockerfile_path            = "${path.module}/image/nextcloud/Dockerfile"
  nextcloud_image_repository = "${local.docker_registry.name}/nextcloud"
  nextcloud_image_tag        = "local"
  nextcloud_image            = "${local.nextcloud_image_repository}:${local.nextcloud_image_tag}"
}

resource "random_password" "admin-password" {
  length = 32
}

module "nextcloud_image" {
  source        = "../modules/buildah"
  dockerfile    = local.dockerfile_path
  tag           = local.nextcloud_image
  keep_locally  = true
  keep_remotely = false
  triggers = {
    files_hash = sha512(jsonencode([
      filesha512("${path.module}/image/nextcloud/files/entrypoint.sh"),
      filesha512("${path.module}/image/nextcloud/files/apache2.conf"),
      filesha512("${path.module}/image/nextcloud/files/apache2_nextcloud.conf"),
      filesha512("${path.module}/image/nextcloud/files/php.ini")
    ]))
  }
}
