resource "tls_private_key" "docker-registry" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "docker-registry" {
  private_key_pem = tls_private_key.docker-registry.private_key_pem

  subject {
    common_name  = local.registry.hostname
    organization = local.homelab.organization
  }

  dns_names = [
    local.registry.hostname,
  ]

  ip_addresses = [
    local.registry.ip
  ]
}

data "local_file" "webserver_ca" {
  filename = local.homelab.ca_cert
}

data "local_file" "webserver_key_ca" {
  filename = local.homelab.ca_key
}

resource "tls_locally_signed_cert" "docker-registry" {
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
  is_ca_certificate     = true
  ca_cert_pem           = data.local_file.webserver_ca.content
  ca_private_key_pem    = data.local_file.webserver_key_ca.content
  cert_request_pem      = tls_cert_request.docker-registry.cert_request_pem
  validity_period_hours = 24*365*100
}

resource "tls_private_key" "docker-client" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "docker-client" {
  private_key_pem = tls_private_key.docker-client.private_key_pem

  subject {
    common_name  = "my-docker-client"
    organization = local.homelab.organization
  }
}

resource "tls_locally_signed_cert" "docker-client" {
  allowed_uses = [
    "key_encipherment",
    "server_auth"
  ]
  ca_cert_pem           = tls_locally_signed_cert.docker-registry.cert_pem
  ca_private_key_pem    = tls_private_key.docker-registry.private_key_pem
  cert_request_pem      = tls_cert_request.docker-client.cert_request_pem
  validity_period_hours = 24*365*100
}