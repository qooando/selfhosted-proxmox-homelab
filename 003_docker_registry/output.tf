resource local_file "ssh_private_key" {
  filename        = "${local.build_path}/docker-registry.key"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0400"
}

resource local_file "docker-registry_yaml" {
  filename = "${local.build_path}/docker-registry.vars.yaml"
  content = yamlencode({
    "ip" : local.registry.ip,
    "hostname" : local.registry.hostname,
    "ssh_username" : local.registry.ssh_username,
    "ssh_key_file" : local_file.ssh_private_key.filename
    "port" : local.registry.port,
    "name" : "${local.registry.hostname}:${local.registry.port}"
    "certs_dir" : "${local.build_path}/${local.registry.hostname}:${local.registry.port}"
  })
}


resource "local_file" "certificate" {
  filename = "${local.build_path}/docker-registry.cert.pem"
  content  = tls_locally_signed_cert.docker-registry.cert_pem
}

resource "local_file" "cfg_ca_pem" {
  filename = "${local.build_path}/${local.registry.hostname}:${local.registry.port}/ca.pem"
  content  = tls_locally_signed_cert.docker-registry.cert_pem
}

resource "local_file" "cfg_cert_pem" {
  filename = "${local.build_path}/${local.registry.hostname}:${local.registry.port}/cert.pem"
  content  = tls_locally_signed_cert.docker-client.cert_pem
}

resource "local_file" "cfg_cert_key" {
  filename = "${local.build_path}/${local.registry.hostname}:${local.registry.port}/key.pem"
  content  = tls_cert_request.docker-client.private_key_pem
}
