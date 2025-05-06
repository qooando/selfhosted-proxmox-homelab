resource "kubernetes_namespace" "gitea" {
  metadata {
    name = "gitea"
  }
}

resource "random_password" "registration-token" {
  length  = 32
  special = false
}

resource "random_password" "admin-password" {
  length  = 32
  special = true
}

resource "postgresql_database" "gitea" {
  name              = "gitea"
  connection_limit  = -1
  allow_connections = true
}

resource "kubernetes_persistent_volume_claim" "gitea-pvc" {
  wait_until_bound = true
  metadata {
    name      = "gitea-pvc"
    namespace = kubernetes_namespace.gitea.metadata.0.name
    annotations = {
      "nfs.io/storage-path" = "gitea"
    }
  }
  spec {
    storage_class_name = local.kubernetes_init.nfs_storage_class_name
    access_modes = [
      "ReadWriteMany"
    ]
    resources {
      requests = {
        storage = "100Gi"
      }
    }
  }
}

resource "helm_release" "gitea" {
  depends_on = [
    kubernetes_persistent_volume_claim.gitea-pvc,
    postgresql_database.gitea
  ]
  repository    = "https://dl.gitea.com/charts/"
  chart         = "gitea"
  name          = "gitea"
  namespace     = kubernetes_namespace.gitea.metadata.0.name
  wait          = true
  wait_for_jobs = true
  timeout       = 60

  values = [
    yamlencode({
      clusterDomain = local.gitea.hostname
      service = {
        http = {
          type = "ClusterIP"
          port = 3000
        }
        ssh = {
          type = "ClusterIP"
          port = 22
        }
      }
      ingress = {
        enabled = false
      }
      deployment = {
        env = [
          {
            name  = "GITEA_RUNNER_REGISTRATION_TOKEN"
            value = random_password.registration-token.result
          }
        ] # env variables
      }
      persistence = {
        enabled      = true
        storageClass = local.kubernetes_init.nfs_storage_class_name
        annotations = {
          "nfs.io/storage-path" = "gitea"
        }
      }
      signing = {
        enabled = false
      }
      gitea = {
        admin = {
          username    = local.gitea.admin_username
          password    = random_password.admin-password.result
          passwordMod = "keepUpdated"
        }
        config = {
          # see https://gitea.com/gitea/helm-gitea#configuration
          # APP_NAME = "Gitea"
          # RUN_MODE = "dev"
          admin = {
            username = local.gitea.admin_username
            password = random_password.admin-password.result
            email    = local.gitea.admin_email
          }
          server = {
            DOMAIN          = local.gitea.hostname
            ROOT_URL        = "https://${local.gitea.hostname}"
            SSH_PORT        = local.gitea.ssh_port
            SSH_LISTEN_PORT = local.gitea.ssh_port
          }
          database = {
            DB_TYPE = "postgres"
            NAME    = local.gitea.db_name
            HOST    = local.postgres.service_host_port
            USER    = local.postgres.default_user
            PASSWD  = local.postgres.default_password
          }
          repository = {
            # ROOT = "/srv"
          }
          cors = {
            ENABLED = false
          }
          # security = {
          #   PASSWORD_COMPLEXITY = "spec"
          # }
          actions = {
            ENABLED = true
          }
        }
        oauth = [
          {
            # see for parameters:
            # https://docs.gitea.com/administration/command-line#admin
            name            = "authentik"
            provider        = "openidConnect"
            key             = authentik_provider_oauth2.gitea.client_id
            secret          = authentik_provider_oauth2.gitea.client_secret
            autoDiscoverUrl = "https://${local.authentik.hostname}/application/o/${authentik_application.gitea.slug}/.well-known/openid-configuration"
            scopes          = "openid email profile"
            iconUrl         = "https://${local.authentik.hostname}/static/dist/assets/icons/icon.svg"
          }
        ]
      }
      redis-cluster = {
        enabled = false
      }
      redis = {
        enabled = false
      }
      postgresql-ha = {
        enabled = false
      }
      postgresql = {
        enabled = false
      }
      additionalConfigFromEnvs = [
        # additional envs
      ]
    })
  ]
}

resource "kubectl_manifest" "gitea-ingress-cert" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "gitea"
      namespace = kubernetes_namespace.gitea.metadata.0.name
    }
    spec = {
      secretName = "gitea-ingress"
      issuerRef = {
        name = local.kubernetes_init.cluster_issuer_name
        kind = "ClusterIssuer"
      }
      dnsNames = [
        local.gitea.hostname
      ]
    }
  })
  wait = true
}

resource "kubectl_manifest" "gitea-ingress" {
  depends_on = [
    kubectl_manifest.gitea-ingress-cert
  ]
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "gitea"
      namespace = kubernetes_namespace.gitea.metadata.0.name
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          match = "Host(`${local.gitea.hostname}`)"
          kind  = "Rule"
          services = [
            {
              name = "gitea-http"
              port = 3000
            }
          ]
        }
      ]
      tls = { secretName = "gitea-ingress" }
    }
  })
}

resource "kubectl_manifest" "gitea-ingress-ssh" {
  depends_on = [
    kubectl_manifest.gitea-ingress-cert
  ]
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRouteTCP"
    metadata = {
      name      = "gitea-ssh"
      namespace = kubernetes_namespace.gitea.metadata.0.name
    }
    spec = {
      entryPoints = [
        local.kubernetes_init.traefik.ssh.entrypoint
      ]
      routes = [
        {
          match = "HostSNI(`${local.gitea.hostname}`)"
          kind  = "Rule"
          services = [
            {
              name = "gitea-ssh"
              port = 22
            }
          ]
        }
      ]
      tls = {
        passthrough = true
      }
      # tls = { secretName = "gitea" }
    }
  })
}
