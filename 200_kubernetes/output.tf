resource "local_file" "kubeconfig" {
  filename = "${local.build_path}/kubeconfig.yaml"
  content = replace(data.remote_file.kubeconfig.content, "127.0.0.1", local.kubernetes.ip)
}

resource local_file "ssh_private_key" {
  filename        = "${local.build_path}/kubernetes.key"
  content         = tls_private_key.ssh.private_key_openssh
  file_permission = "0400"
}

resource "local_file" "kubernetes_yaml" {
  filename = "${local.build_path}/kubernetes.vars.yaml"
  content = yamlencode({
    ip           = local.kubernetes.ip
    hostname     = local.kubernetes.hostname
    kubeconfig   = local_file.kubeconfig.filename
    ssh_username = local.kubernetes.ssh_username
    ssh_key      = local_file.ssh_private_key.filename
  })
}
