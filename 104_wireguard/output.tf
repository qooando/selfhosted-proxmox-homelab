resource local_file "ssh_private_key" {
  filename        = "${local.build_path}/wireguard.ssh.key"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0400"
}

resource "local_file" "wireguard_yaml" {
  filename = "${local.build_path}/wireguard.vars.yaml"
  content = yamlencode({
    "ip"             = local.wireguard.ip
    "hostname"       = local.wireguard.hostname
    "ssh_username"   = local.wireguard.ssh_username
    "ssh_password"   = random_password.ssh_password.result
    "ssh_key_file"   = local_file.ssh_private_key.filename
    "vpn_udp_port"   = local.wireguard.udp_port,
    "admin_password" = random_password.wg-dashboard.result
  })
}

resource "local_file" "wireguard_server_conf" {
  filename = "${local.build_vpn_path}/server.conf"
  content  = local.wireguard_sever_conf
}

resource "local_file" "wireguard_client_conf" {
  filename = "${local.build_vpn_path}/client.conf"
  content  = local.wireguard_client_conf

  provisioner "local-exec" {
    command = "qrencode -t png -o ${local.build_vpn_path}/client.png < ${local.build_vpn_path}/client.conf"
  }
}
