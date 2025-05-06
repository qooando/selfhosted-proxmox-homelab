resource local_file "ssh_private_key" {
  filename        = "${local.build_path}/nfs.key"
  content         = tls_private_key.ssh.private_key_pem
  file_permission = "0400"
}

resource local_file "nfs_yaml" {
  filename = "${local.build_path}/nfs.vars.yaml"
  content = yamlencode({
    "ip" : local.nfs.ip,
    "hostname" : local.nfs.hostname,
    "ssh_username" : local.nfs.ssh_username,
    "ssh_key_file" : local_file.ssh_private_key.filename
  })
}

