resource "local_file" "ca_cert" {
  filename = "${local.build_path}/${local.homelab.node_name}_ca.pem"
  content  = tls_self_signed_cert.ca.cert_pem
}

resource "local_file" "ca_key" {
  filename = "${local.build_path}/${local.homelab.node_name}_ca_key.pem"
  content  = tls_self_signed_cert.ca.private_key_pem
}

resource "local_file" "vars_yaml" {
  filename = "${local.build_path}/homelab.vars.yaml"
  content = yamlencode(merge(
    local.homelab,
    {
      gui_hostname = "homelab.${local.homelab.hostname}",
      "ca_cert"    = local_file.ca_cert.filename
      "ca_key"     = local_file.ca_key.filename
    }
  ))
}

