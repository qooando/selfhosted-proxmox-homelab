resource "kubernetes_namespace" "postgres" {
  metadata {
    name = "postgres"
  }
}

resource "random_password" "default-password" {
  length  = 32
  special = true
}

resource "kubernetes_config_map" "postgres-settings" {
  metadata {
    name      = "postgres-settings"
    namespace = kubernetes_namespace.postgres.metadata.0.name
  }
  data = {
    "postgres.conf" = templatefile("${path.module}/configs/postgres.conf", {})
    "pg_hba.conf" = templatefile("${path.module}/configs/pg_hba.conf", {})
    "start.sh" = templatefile("${path.module}/configs/start.sh", {})
  }
}

resource "kubernetes_persistent_volume_claim" "postgres-pvc" {
  wait_until_bound = true
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.postgres.metadata.0.name
    annotations = {
      "nfs.io/storage-path" = "postgres"
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

resource "kubernetes_deployment" "postgres" {
  depends_on = [
    module.postgres_image
  ]
  # see https://hub.docker.com/_/postgres/
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.postgres.metadata.0.name
  }
  spec {
    replicas = "1"
    selector {
      match_labels = {
        app = "postgres"
      }
    }
    template {
      metadata {
        name      = "postgres"
        namespace = kubernetes_namespace.postgres.metadata.0.name
        labels = {
          app = "postgres"
        }
        annotations = {
          postgres_settings_hash = sha512(jsonencode(kubernetes_config_map.postgres-settings.data))
          image_hash = module.postgres_image.hash
        }
      }
      spec {
        container {
          name  = "postgres"
          image = local.docker_postgres_tag
          image_pull_policy = "Always"
          env {
            name  = "POSTGRES_PASSWORD"
            value = random_password.default-password.result
          }
          env {
            name  = "POSTGRES_USER"
            value = local.postgres.default_user
          }
          env {
            name  = "POSTGRES_DB"
            value = local.postgres.default_db
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }
          volume_mount {
            name       = "settings"
            mount_path = "/etc/postgres.conf"
            sub_path   = "postgres.conf"
          }
          volume_mount {
            name       = "settings"
            mount_path = "/etc/pg_hba.conf"
            sub_path   = "pg_hba.conf"
          }
          volume_mount {
            name       = "settings"
            mount_path = "/start.sh"
            sub_path   = "start.sh"
          }
          port {
            name           = "postgres"
            container_port = 5432
          }
          command = [
            "bash",
            "/start.sh"
          ]
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres-pvc.metadata.0.name
          }
        }
        volume {
          name = "settings"
          config_map {
            name = kubernetes_config_map.postgres-settings.metadata.0.name
          }
        }
      }
    }
  }
  timeouts {
    create = "1m"
    update = "1m"
    delete = "2m"
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.postgres.metadata.0.name
  }
  spec {
    selector = {
      app = "postgres"
    }
    # type = "ClusterIP"
    type = "NodePort"
    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
      node_port   = 30002 #35432
    }
  }
}

locals {
  service = {
    host      = "${kubernetes_service.postgres.metadata.0.name}.${kubernetes_namespace.postgres.metadata.0.name}" #".svc.cluster.local"
    port      = "${kubernetes_service.postgres.spec.0.port.0.port}"
    node_port = "${kubernetes_service.postgres.spec.0.port.0.node_port}"
  }
}