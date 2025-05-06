resource "kubernetes_config_map" "act-runner-settings" {
  metadata {
    name      = "act-runner-settings"
    namespace = kubernetes_namespace.gitea.metadata.0.name
  }
  data = {
    "config.yaml" = templatefile("${path.module}/configs/act_runner_config.yaml", {})
  }
}

resource "kubernetes_deployment" "act-runner" {
  metadata {
    name      = "act-runner"
    namespace = kubernetes_namespace.gitea.metadata.0.name
  }
  spec {
    replicas = "1"
    selector {
      match_labels = {
        app = "act-runner"
      }
    }
    template {
      metadata {
        name      = "act-runner"
        namespace = kubernetes_namespace.gitea.metadata.0.name
        labels = {
          app = "act-runner"
        }
        annotations = {
          settings_hash = sha512(jsonencode(kubernetes_config_map.act-runner-settings.data))
        }
      }
      spec {
        container {
          name  = "act-runner"
          image = "gitea/act_runner"
          # url = "gitea-http.${kubernetes_namespace.gitea.metadata.0.name}"
          volume_mount {
            name       = "settings"
            mount_path = "/etc/act_runner/config.yaml"
            sub_path   = "config.yaml"
          }
          env {
            name  = "CONFIG_FILE"
            value = "/etc/act_runner/config.yaml"
          }
          env {
            name  = "GITEA_INSTANCE_URL"
            value = "http://gitea-http.${kubernetes_namespace.gitea.metadata.0.name}:3000"
          }
          env {
            name  = "GITEA_RUNNER_REGISTRATION_TOKEN"
            value = random_password.registration-token.result
          }
          # env {
          #   name = "GITEA_RUNNER_NAME"
          #   value =
          # }
        }
        volume {
          name = "settings"
          config_map {
            name = kubernetes_config_map.act-runner-settings.metadata.0.name
          }
        }
      }
    }
  }
}