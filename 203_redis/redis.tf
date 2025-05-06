resource "random_password" "default_password" {
  length  = 32
  special = true
}

resource "kubernetes_namespace" "redis" {
  metadata {
    name = "redis"
  }
}

resource "kubernetes_config_map" "redis-settings" {
  metadata {
    name      = "redis-settings"
    namespace = kubernetes_namespace.redis.metadata.0.name
  }
  data = {
    "redis.conf" = templatefile("${path.module}/configs/redis.conf", {})
    "users.acl" = templatefile("${path.module}/configs/users.acl", {
      username = local.redis.default_username
      password = random_password.default_password.result
    })
  }
}

resource "kubernetes_persistent_volume_claim" "redis-pvc" {
  wait_until_bound = true
  metadata {
    name      = "redis-pvc"
    namespace = kubernetes_namespace.redis.metadata.0.name
    annotations = {
      "nfs.io/storage-path" = "redis"
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

resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.redis.metadata.0.name
  }
  spec {
    replicas = "1"
    selector {
      match_labels = {
        app = "redis"
      }
    }
    template {
      metadata {
        name      = "redis"
        namespace = kubernetes_namespace.redis.metadata.0.name
        labels = {
          app = "redis"
        }
        annotations = {
          settings_hash = sha512(jsonencode(kubernetes_config_map.redis-settings.data))
        }
      }
      spec {
        container {
          name  = "redis"
          image = "redis:8.0-M04-alpine"
          command = [
            "docker-entrypoint.sh",
            "/etc/redis.conf"
          ]
          port {
            name           = "redis"
            container_port = 6379
          }
          volume_mount {
            mount_path = "/data"
            name       = "data"
          }
          volume_mount {
            mount_path = "/etc/redis.conf"
            name       = "settings"
            sub_path   = "redis.conf"
          }
          volume_mount {
            mount_path = "/etc/redis/users.acl"
            name       = "settings"
            sub_path   = "users.acl"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.redis-pvc.metadata.0.name
          }
        }
        volume {
          name = "settings"
          config_map {
            name = kubernetes_config_map.redis-settings.metadata.0.name
          }
        }
      }
    }
  }
}
resource "kubernetes_service" "redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace.redis.metadata.0.name
  }
  spec {
    selector = {
      app = "redis"
    }
    # type = "ClusterIP"
    type = "NodePort"
    port {
      name        = "postgres"
      port        = 6379
      target_port = 6379
      node_port   = 30009 #36379
    }
  }
}

locals {
  service = {
    host      = "${kubernetes_service.redis.metadata.0.name}.${kubernetes_namespace.redis.metadata.0.name}" # ".svc.cluster.local"
    port      = "${kubernetes_service.redis.spec.0.port.0.port}"
    node_port = "${kubernetes_service.redis.spec.0.port.0.node_port}"
  }
}