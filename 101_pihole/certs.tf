resource "tls_private_key" "webserver" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "webserver" {
  private_key_pem = tls_private_key.webserver.private_key_pem

  subject {
    common_name  = local.pihole.hostname
    organization = local.homelab.organization
  }

  dns_names = [
    local.pihole.hostname,
    local.pihole.ip
  ]

}

data "local_file" "webserver_ca" {
  filename = local.homelab.ca_cert
}

data "local_file" "webserver_key_ca" {
  filename = local.homelab.ca_key
}

resource "tls_locally_signed_cert" "webserver" {
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth"
  ]
  ca_cert_pem           = data.local_file.webserver_ca.content
  ca_private_key_pem    = data.local_file.webserver_key_ca.content
  cert_request_pem      = tls_cert_request.webserver.cert_request_pem
  validity_period_hours = 24*365*100
}

