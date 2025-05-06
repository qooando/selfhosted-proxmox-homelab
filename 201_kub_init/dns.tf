resource "ssh_resource" "dns" {
  host        = local.kubernetes.ip
  user        = local.kubernetes.ssh_username
  private_key = file(local.kubernetes.ssh_key)

  commands = [
    "resolvectl dns eth0 ${local.pihole.ip}"
  ]
}