resource "kubernetes_namespace" "auth" {
  metadata {
    name = "auth"
  }
}

resource "random_password" "secure-key" {
  length = 32
}

resource "random_password" "bootstrap-admin" {
  length = 32
}

resource "random_password" "bootstrap-token" {
  length = 32
}

resource "postgresql_database" "authentik" {
  name = "authentik"
}

resource "kubectl_manifest" "authentik-ingress-cert" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "authentik"
      namespace = kubernetes_namespace.auth.metadata.0.name
    }
    spec = {
      secretName = "authentik-ingress"
      issuerRef = {
        name = local.kubernetes_init.cluster_issuer_name
        kind = "ClusterIssuer"
      }
      dnsNames = [
        local.authentik.hostname
      ]
    }
  })
  wait = true
}

resource "kubernetes_config_map" "authentik-envs" {
  metadata {
    name      = "authentik-envs"
    namespace = kubernetes_namespace.auth.metadata.0.name
  }
  data = {

  }
}

resource "null_resource" "chart-change" {
  triggers = {
    version = "1.0.2"
  }
}

resource "helm_release" "authentik" {
  lifecycle {
    replace_triggered_by = [
      null_resource.chart-change
    ]
  }
  repository = "https://charts.goauthentik.io"
  chart      = "authentik"
  name       = "authentik"
  namespace  = kubernetes_namespace.auth.metadata.0.name
  wait       = true
  wait_for_jobs = true
  # timeout    = 60
  
  values = [
    yamlencode({
      authentik = {
        bootstrap_token    = random_password.bootstrap-token.result
        bootstrap_password = random_password.bootstrap-admin.result
        secret_key         = random_password.secure-key.result
        error_reporting = {
          enabled = false
        }
        postgresql = {
          host     = local.postgres.service_host
          port     = local.postgres.service_port
          name     = postgresql_database.authentik.name
          user     = local.postgres.default_user
          password = local.postgres.default_password
        }
        redis = {
          host     = local.redis.service_host
          username = local.redis.default_username
          password = local.redis.default_password
        }
      }
      server = {
        envFrom = [
          {
            configMapRef = {
              name = kubernetes_config_map.authentik-envs.metadata.0.name
            }
          }
        ]
        containerPorts = {
          http    = 80
          https   = 443
          metrics = 9300
          # ldap    = 389
        }
        ingress = {
          ingressClassName = "traefik"
          enabled          = true
          hosts = [
            local.authentik.hostname
          ]
          tls = [
            {
              hosts = [
                local.authentik.hostname
              ]
              secretName = "authentik-ingress"
            }
          ]
        }
      }
    })
  ]
}
