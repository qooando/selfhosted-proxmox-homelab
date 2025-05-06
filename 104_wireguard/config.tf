locals {
  install_script       = "${path.module}/configs/install.sh"
  server_conf_path     = "${path.module}/configs/server.conf"
  client_conf_path     = "${path.module}/configs/clients.conf"
  wgdashboard_ini_path = "${path.module}/configs/wg-dashboard.ini"
}

resource "null_resource" "wireguard-keys" {
  provisioner "local-exec" {
    command = join("; ", [
      "wg genkey | tee ${local.build_vpn_path}/server.key | wg pubkey > ${local.build_vpn_path}/server.key.pub",
      "wg genkey | tee ${local.build_vpn_path}/client.key | wg pubkey > ${local.build_vpn_path}/client.key.pub"
    ])
  }
}

data "local_file" "server-private-key" {
  depends_on = [
    null_resource.wireguard-keys
  ]
  filename = "${local.build_vpn_path}/server.key"
}

data "local_file" "server-public-key" {
  depends_on = [
    null_resource.wireguard-keys
  ]
  filename = "${local.build_vpn_path}/server.key.pub"
}

data "local_file" "client-private-key" {
  depends_on = [
    null_resource.wireguard-keys
  ]
  filename = "${local.build_vpn_path}/client.key"
}

data "local_file" "client-public-key" {
  depends_on = [
    null_resource.wireguard-keys
  ]
  filename = "${local.build_vpn_path}/client.key.pub"
}

locals {
  conf_variables = {
    listen_port    = local.wireguard.udp_port,
    server_private_key = trimspace(data.local_file.server-private-key.content),
    server_public_key = trimspace(data.local_file.server-public-key.content),
    client_private_key = trimspace(data.local_file.client-private-key.content),
    client_public_key = trimspace(data.local_file.client-public-key.content),
    dns            = local.pihole.ip
    gateway        = local.homelab.gateway
    port           = local.wireguard.udp_port
    public_gateway = local.wireguard.public_gateway_host
    public_port    = local.wireguard.udp_port
  }
  wireguard_client_conf = templatefile(local.client_conf_path, local.conf_variables)
  wireguard_sever_conf = templatefile(local.server_conf_path, local.conf_variables)
  wgdashboard_ini = templatefile(local.wgdashboard_ini_path, local.conf_variables)
}

resource "ssh_resource" "configure-lxc" {
  host     = local.homelab.ip
  user     = split("@", local.homelab.ssh_username)[0]
  password = local.homelab.ssh_password

  depends_on = [
    proxmox_virtual_environment_container.wireguard
  ]

  commands = [
    "echo 'lxc.cgroup.devices.allow: c 10:200 rwm' >> /etc/pve/lxc/${local.wireguard.container_id}.conf",
    "echo 'lxc.mount.entry: /dev/net dev/net none bind,create=dir' >> /etc/pve/lxc/${local.wireguard.container_id}.conf",
    "lxc-stop --name ${local.wireguard.container_id}",
    "sleep 5",
    "lxc-start --name ${local.wireguard.container_id}"
  ]
}

resource "ssh_resource" "first-install" {
  depends_on = [
    proxmox_virtual_environment_container.wireguard,
    ssh_resource.configure-lxc
  ]
  triggers = {
    hashes = sha512(jsonencode([
      filesha512(local.install_script),
      filesha512(local.server_conf_path)
    ]))
  }

  user        = local.wireguard.ssh_username
  host        = local.wireguard.ip
  private_key = tls_private_key.ssh.private_key_openssh

  file {
    content     = local.wireguard_sever_conf
    destination = "/etc/wireguard/wg0.conf"
  }

  file {
    content     = local.wgdashboard_ini
    destination = "/opt/WGDashboard/src/wg-dashboard.ini"
  }

  commands = [
    "reboot"
  ]

  timeout = "1m"
}
