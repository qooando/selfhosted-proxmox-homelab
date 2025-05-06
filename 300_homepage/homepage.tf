resource "kubernetes_namespace" "homepage" {
  metadata {
    name = "homepage"
  }
}

resource "kubernetes_config_map" "homepage-settings" {
  metadata {
    name      = "homepage-settings"
    namespace = kubernetes_namespace.homepage.metadata.0.name
  }
  data = {
    "settings.yaml" = templatefile("${path.module}/configs/settings.yaml", {
      host = local.homelab.node_name
    })
    "kubernetes.yaml" = templatefile("${path.module}/configs/kubernetes.yaml", {}),
    "custom.css"  = ""
    "custom.js"   = ""
    "bookmarks.yaml" = templatefile("${path.module}/configs/bookmarks.yaml", {})
    "services.yaml" = templatefile("${path.module}/configs/services.yaml", {})
    "widgets.yaml" = templatefile("${path.module}/configs/widgets.yaml", {})
    "docker.yaml" = ""
  }
}

locals {
  homepage_settings_hash = sha512(jsonencode(kubernetes_config_map.homepage-settings.data))
}

resource "kubernetes_deployment" "homepage" {
  metadata {
    name      = "homepage"
    namespace = kubernetes_namespace.homepage.metadata.0.name
    labels = {
      app = "homepage"
    }
  }
  spec {
    replicas = "1"
    selector {
      match_labels = {
        app = "homepage"
      }
    }
    template {
      metadata {
        labels = {
          app = "homepage"
        }
        annotations = {
          # update on config update
          hashes = jsonencode([
            local.homepage_settings_hash
          ])
        }
      }
      spec {
        container {
          name  = "homepage"
          image = "ghcr.io/gethomepage/homepage:latest"
          port {
            container_port = 3000
          }
          env {
            name = "HOMEPAGE_ALLOWED_HOSTS"
            value = join(",", local.homepage.hostnames)
          }
          volume_mount {
            name       = "settings"
            mount_path = "/app/config/custom.js"
            sub_path   = "custom.js"
            # read_only  = true   # breaks homepage, it wants the folder to be readable
          }
          volume_mount {
            name       = "settings"
            mount_path = "/app/config/custom.css"
            sub_path   = "custom.css"
          }
          volume_mount {
            name       = "settings"
            mount_path = "/app/config/bookmarks.yaml"
            sub_path   = "bookmarks.yaml"
          }
          volume_mount {
            name       = "settings"
            mount_path = "/app/config/docker.yaml"
            sub_path   = "docker.yaml"
          }
          volume_mount {
            name       = "settings"
            mount_path = "/app/config/kubernetes.yaml"
            sub_path   = "kubernetes.yaml"
          }
          volume_mount {
            name       = "settings"
            mount_path = "/app/config/services.yaml"
            sub_path   = "services.yaml"
          }
          volume_mount {
            name       = "settings"
            mount_path = "/app/config/settings.yaml"
            sub_path   = "settings.yaml"
          }
          volume_mount {
            name       = "settings"
            mount_path = "/app/config/widgets.yaml"
            sub_path   = "widgets.yaml"
          }
          # see https://gethomepage.dev/installation/k8s/#deployment
          volume_mount {
            name       = "logs"
            mount_path = "/app/config/logs"
          }
        }
        volume {
          name = "logs"
          host_path {
            path = "/mnt/homepage/logs"
          }
        }
        volume {
          name = "settings"
          config_map {
            name = kubernetes_config_map.homepage-settings.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "homepage" {
  metadata {
    name      = "homepage"
    namespace = kubernetes_namespace.homepage.metadata.0.name
  }
  spec {
    selector = {
      "app" = "homepage"
    }
    port {
      protocol    = "TCP"
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubectl_manifest" "homepage-ingress-cert" {
  depends_on = [
    kubernetes_deployment.homepage
  ]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "homepage"
      namespace = kubernetes_namespace.homepage.metadata.0.name
    }
    spec = {
      secretName = "homepage"
      issuerRef = {
        name = local.kubernetes_init.cluster_issuer_name
        kind = "ClusterIssuer"
      }
      dnsNames = local.homepage.hostnames
    }
  })
}

resource "kubectl_manifest" "homepage-ingress" {
  depends_on = [
    kubectl_manifest.homepage-ingress-cert
  ]
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "homepage"
      namespace = kubernetes_namespace.homepage.metadata.0.name
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          match = join(" || ", [for h in local.homepage.hostnames : "Host(`${h}`)"])
          kind = "Rule"
          services = [
            {
              name = kubernetes_service.homepage.metadata.0.name
              port = kubernetes_service.homepage.spec.0.port.0.port
            }
          ]
        }
      ]
      tls = {
        secretName = "homepage"
      }
    }
  })
}

resource "pihole_dns_record" "homepage" {
  for_each = toset(local.homepage.hostnames)
  domain = each.value
  ip     = local.kubernetes.ip
}