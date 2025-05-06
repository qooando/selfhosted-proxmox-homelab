resource "ssh_resource" "nfs-dependencies" {
  host = local.kubernetes.ip
  user = local.kubernetes.ssh_username
  private_key = file(local.kubernetes.ssh_key)

  commands = [
    "apt install -y nfs-common"
  ]
}

resource "kubernetes_namespace" "nfs" {
  metadata {
    name = "nfs"
  }
}

resource "helm_release" "nfs-provisioner" {
  repository    = "https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
  chart         = "nfs-subdir-external-provisioner"
  name          = "nfs-subdir-external-provisioner"
  wait          = true
  wait_for_jobs = true
  timeout       = 60
  namespace     = kubernetes_namespace.nfs.metadata.0.name

  values = [
    jsonencode({
      nfs = {
        server     = local.nfs.ip
        path       = "/srv/share"
        volumeName = "nfs-root"
      }
    })
  ]
}

resource "kubernetes_storage_class" "nfs-storage-class" {
  depends_on = [
    helm_release.nfs-provisioner
  ]
  storage_provisioner = "cluster.local/nfs-subdir-external-provisioner"
  metadata {
    name = "nfs"
  }
  parameters = {
    pathPattern = "$${.PVC.annotations.nfs.io/storage-path}"
    onDelete    = "retain"
  }
}
