resource "kubernetes_persistent_volume_claim" "drive" {
  wait_until_bound = true
  metadata {
    name      = "drive-pvc"
    namespace = kubernetes_namespace.drive.metadata.0.name
    annotations = {
      "nfs.io/storage-path" = "drive"
    }
  }
  spec {
    storage_class_name = local.kubernetes_init.nfs_storage_class_name
    access_modes = [
      "ReadWriteMany"
    ]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

