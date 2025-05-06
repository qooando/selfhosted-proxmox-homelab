resource "local_file" "kubernetes_init_yaml" {
  filename = "${local.build_path}/kubernetes.init.vars.yaml"
  content = yamlencode({
    "nfs_storage_class_name" = kubernetes_storage_class.nfs-storage-class.metadata.0.name
    "cluster_issuer_name"    = "cluster-ca-issuer"
    "cluster_ca"             = "${local.build_path}/kubernetes_ca.pem"
    "traefik" = {
      "dashboard" = {
        "hostnames" = local.traefik_dashboard.hostnames
      }
      "ssh" = {
        "entrypoint" = local.traefik.ssh_entrypoint
        "port"       = local.traefik.ssh_port
      }
    }
  })
}

resource "local_file" "kubernetes-ca" {
  filename = "${local.build_path}/kubernetes_ca.pem"
  content  = data.kubernetes_secret.cluster-ca.data["ca.crt"]
}