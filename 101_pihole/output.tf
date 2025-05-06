resource "local_file" "ssh_private_key" {
  filename        = "${local.build_path}/pihole.key"
  content         = tls_private_key.ssh.private_key_openssh
  file_permission = "0400"
}

resource "local_file" "pihole_certifiate" {
  filename = "${local.build_path}/pihole.pem"
  content = tls_locally_signed_cert.webserver.cert_pem
}

resource "local_file" "pihole_yaml" {
  filename = "${local.build_path}/pihole.vars.yaml"
  content = yamlencode({
    ip            = local.pihole.ip
    hostname      = local.pihole.hostname
    ssh_username  = local.pihole.ssh_username
    ssh_password  = random_password.ssh_password.result
    ssh_key_file  = local_file.ssh_private_key.filename
    web_password  = random_password.webserver_api_password.result
    web_cert_file = local_file.pihole_certifiate.filename
    api_url       = "https://${local.pihole.hostname}"
  })
}
