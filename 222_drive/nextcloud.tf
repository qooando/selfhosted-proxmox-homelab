resource "postgresql_database" "nextcloud" {
  name = "nextcloud"
}

resource "kubernetes_config_map" "nextcloud-configs" {
  metadata {
    name      = "nextcloud-configs"
    namespace = kubernetes_namespace.drive.metadata.0.name
  }
  data = {
    "init.sh" = templatefile("${path.module}/configs/nextcloud/init.sh", {
      oauth2_client_id     = authentik_provider_oauth2.nextcloud.client_id
      oauth2_client_secret = authentik_provider_oauth2.nextcloud.client_secret
      oauth2_hostname      = local.authentik.hostname
      discovery_uri        = "https://${local.authentik.hostname}/application/o/${authentik_application.nextcloud.slug}/.well-known/openid-configuration"
      oauth2_app_slug      = authentik_application.nextcloud.slug
      domain               = local.homelab.node_name
      tld                  = "local"
      hostname             = local.drive.hostname
    })
    "apache2_nextcloud.conf" = templatefile("${path.module}/configs/nextcloud/apache2_nextcloud.conf", {
      hostname = local.drive.hostname
    })
    "logging.config.php" = file("${path.module}/configs/nextcloud/logging.config.php")
    "domains.config.php" = templatefile("${path.module}/configs/nextcloud/domains.config.php", {
      hostname = local.drive.hostname
    })
    "files.config.php" = file("${path.module}/configs/nextcloud/files.config.php")
  }
}

resource "kubernetes_config_map" "nextcloud-envs" {
  metadata {
    name      = "nextcloud-envs"
    namespace = kubernetes_namespace.drive.metadata.0.name
  }
  data = {
    DB_NAME           = postgresql_database.nextcloud.name
    DB_HOST           = local.postgres.service_host_port
    DB_USER           = local.postgres.default_user
    DB_PASSWORD       = local.postgres.default_password
    DB_ADMIN_USER     = local.postgres.default_user
    DB_ADMIN_PASSWORD = local.postgres.default_password
  }
}

resource "kubernetes_deployment" "nextcloud" {
  metadata {
    name      = "nextcloud"
    namespace = kubernetes_namespace.drive.metadata.0.name
  }
  spec {
    replicas = "1"
    selector {
      match_labels = {
        app = "nextcloud"
      }
    }
    template {
      metadata {
        name      = "nextcloud"
        namespace = kubernetes_namespace.drive.metadata.0.name
        labels = {
          app = "nextcloud"
        }
        annotations = {
          config_hash = sha512(jsonencode(kubernetes_config_map.nextcloud-configs.data))
          image_hash = module.nextcloud_image.hash
        }
      }
      spec {
        host_aliases {
          hostnames = [
            local.authentik.hostname
          ]
          ip = local.kubernetes.ip
        }
        container {
          name              = "nextcloud"
          image             = local.nextcloud_image
          image_pull_policy = "Always"
          env_from {
            config_map_ref {
              name = kubernetes_config_map.nextcloud-envs.metadata.0.name
            }
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/www/nextcloud/data"
            sub_path   = "data"
          }
          volume_mount {
            name       = "data"
            mount_path = "/var/www/nextcloud/config"
            sub_path   = "config"
          }
          volume_mount {
            mount_path = "/var/www/nextcloud/config/logging.config.php"
            name       = "configs"
            sub_path   = "logging.config.php"
          }
          volume_mount {
            mount_path = "/var/www/nextcloud/config/domains.config.php"
            name       = "configs"
            sub_path   = "domains.config.php"
          }
          volume_mount {
            mount_path = "/var/www/nextcloud/config/files.config.php"
            name       = "configs"
            sub_path   = "files.config.php"
          }
          volume_mount {
            mount_path = "/var/www/nextcloud/init.sh"
            name       = "configs"
            sub_path   = "init.sh"
          }
          volume_mount {
            mount_path = "/etc/apache2/sites-available/nextcloud.conf"
            name       = "configs"
            sub_path   = "apache2_nextcloud.conf"
          }
          port {
            container_port = 80
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.drive.metadata.0.name
          }
        }
        volume {
          name = "configs"
          config_map {
            name = kubernetes_config_map.nextcloud-configs.metadata.0.name
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

resource "kubernetes_service" "drive" {
  metadata {
    name      = "nextcloud"
    namespace = kubernetes_namespace.drive.metadata.0.name
  }
  spec {
    selector = {
      app = "nextcloud"
    }
    port {
      port        = 80
      target_port = 80
    }
  }
}


resource "kubectl_manifest" "nextcloud-ingress-cert" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "nextcloud"
      namespace = kubernetes_namespace.drive.metadata.0.name
    }
    spec = {
      secretName = "nextcloud-ingress"
      issuerRef = {
        name = local.kubernetes_init.cluster_issuer_name
        kind = "ClusterIssuer"
      }
      dnsNames = [
        local.drive.hostname
      ]
    }
  })
  wait = true
}

resource "kubectl_manifest" "nextcloud-ingress" {
  depends_on = [
    kubectl_manifest.nextcloud-ingress-cert
  ]
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "nextcloud"
      namespace = kubernetes_namespace.drive.metadata.0.name
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          match = "Host(`${local.drive.hostname}`)"
          kind  = "Rule"
          services = [
            {
              name           = "nextcloud"
              port           = 80
              passHostHeader = true
            }
          ]
        }
      ]
      tls = { secretName = "nextcloud-ingress" }
    }
  })
}
