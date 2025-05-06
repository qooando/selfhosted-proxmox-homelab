resource "kubernetes_namespace" "calibre" {
  metadata {
    name = "calibre"
  }
}

resource "postgresql_database" "calibre" {
  name              = "calibre"
  connection_limit  = -1
  allow_connections = true
}

resource "kubernetes_config_map" "calibre-settings" {
  metadata {
    name      = "calibre-settings"
    namespace = kubernetes_namespace.calibre.metadata.0.name
  }
  data = {}
}

resource "kubernetes_persistent_volume_claim" "calibre-pvc" {
  wait_until_bound = true
  metadata {
    name      = "calibre-pvc"
    namespace = kubernetes_namespace.calibre.metadata.0.name
    annotations = {
      "nfs.io/storage-path" = "calibre"
    }
  }
  spec {
    storage_class_name = local.kubernetes_init.nfs_storage_class_name
    access_modes = [
      "ReadWriteMany"
    ]
    resources {
      requests = {
        storage = "50Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "drive-pvc" {
  wait_until_bound = true
  metadata {
    name      = "drive-pvc"
    namespace = kubernetes_namespace.calibre.metadata.0.name
    annotations = {
      "nfs.io/storage-path" = "drive/data/admin/files/calibre"
    }
  }
  spec {
    storage_class_name = local.kubernetes_init.nfs_storage_class_name
    access_modes = [
      "ReadWriteMany"
    ]
    resources {
      requests = {
        storage = "50Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "calibre" {
  metadata {
    name      = "calibre"
    namespace = kubernetes_namespace.calibre.metadata.0.name
  }
  spec {
    replicas = "1"
    selector {
      match_labels = {
        app = "calibre"
      }
    }
    template {
      metadata {
        name      = "calibre"
        namespace = kubernetes_namespace.calibre.metadata.0.name
        labels = {
          app = "calibre"
        }
        annotations = {
          settings_hash = sha512(jsonencode(kubernetes_config_map.calibre-settings.data))
        }
      }
      spec {
        # restart_policy = "unless-stopped"
        container {
          name  = "calibre"
          image = "crocodilestick/calibre-web-automated:latest"
          # image_pull_policy = "Always"
          port {
            container_port = 8083
          }
          env {
            name  = "TZ"
            value = "Europe/Rome"
          }
          volume_mount {
            mount_path = "/config"
            name       = "data"
            sub_path   = "config"
          }
          volume_mount {
            mount_path = "/cwa-book-ingest"
            name       = "data-drive"
            sub_path   = "Nuovi Libri"
          }
          volume_mount {
            mount_path = "/calibre-library"
            name       = "data-drive"
            sub_path   = "Biblioteca"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.calibre-pvc.metadata.0.name
          }
        }
        volume {
          name = "data-drive"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.drive-pvc.metadata.0.name
          }
        }
        volume {
          name = "settings"
          config_map {
            name = kubernetes_config_map.calibre-settings.metadata.0.name
          }
        }
        volume {
          name = "temporary"
          empty_dir {
            size_limit = "100Mi"
          }
        }
      }
    }
  }
  # timeouts {
  #   create = "1m"
  #   update = "1m"
  #   delete = "2m"
  # }
}

resource "kubernetes_service" "calibre" {
  metadata {
    name      = "calibre"
    namespace = kubernetes_namespace.calibre.metadata.0.name
  }
  spec {
    selector = {
      app = "calibre"
    }
    port {
      port        = 8083
      target_port = 8083
    }
  }
}

resource "kubectl_manifest" "calibre-ingress-cert" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "calibre"
      namespace = kubernetes_namespace.calibre.metadata.0.name
    }
    spec = {
      secretName = "calibre-ingress"
      issuerRef = {
        name = local.kubernetes_init.cluster_issuer_name
        kind = "ClusterIssuer"
      }
      dnsNames = [
        local.books.hostname
      ]
    }
  })
  wait = true
}

resource "kubectl_manifest" "calibre-ingress" {
  depends_on = [
    kubectl_manifest.calibre-ingress-cert
  ]
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "calibre"
      namespace = kubernetes_namespace.calibre.metadata.0.name
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          match = "Host(`${local.books.hostname}`)"
          kind  = "Rule"
          services = [
            {
              name = kubernetes_service.calibre.metadata.0.name
              port = kubernetes_service.calibre.spec.0.port.0.port
            }
          ]
        }
      ]
      tls = { secretName = "calibre-ingress" }
    }
  })
}
