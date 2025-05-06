resource "local_file" "drive_yaml" {
  filename = "${local.build_path}/drive.vars.yaml"
  content = yamlencode({
    hostname       = local.drive.hostname
    admin_username = local.drive.admin_username
    admin_password = random_password.admin-password.result
    admin_email    = local.drive.admin_email
  })
}