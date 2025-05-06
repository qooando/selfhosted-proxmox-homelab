resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
  }
}

# # https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml
resource "helm_release" "traefik-crds" {
  repository      = "https://traefik.github.io/charts"
  chart           = "traefik-crds"
  name = "traefik-crd"
  # namespace       = var.config.namespace
  cleanup_on_fail = true
  replace         = true
  force_update    = true
  wait_for_jobs   = true

  # values = [
  #   yamlencode({
  #     imagePullSecrets = [
  #       local.docker_hub_secret_name
  #     ]
  #   })
  # ]
}

resource "helm_release" "traefik" {
  depends_on = [
    helm_release.traefik-crds
  ]
  repository      = "https://traefik.github.io/charts"
  chart           = "traefik"
  name            = "traefik"
  namespace       = kubernetes_namespace.traefik.metadata.0.name
  skip_crds       = true
  cleanup_on_fail = true

  values = [
    yamlencode({
      dashboard = {
        enabled = true
      }
      ports = {
        web = {
          redirections = {
            entryPoint = {
              to     = "websecure"
              scheme = "https"
            }
          }
          forwardedHeaders = {
            insecure = true
            # trustedIPs = []
          }
          proxyProtocol = {
            insecure = true
            # trustedIPs = []
          }
        }
        websecure = {
          forwardedHeaders = {
            insecure = true
            # trustedIPs = []
          }
          proxyProtocol = {
            insecure = true
            # trustedIPs = []
          }
        }
        (local.traefik.ssh_entrypoint) = {
          port = local.traefik.ssh_port
          expose = {
            default = true
          }
          exposedPort = local.traefik.ssh_port
          protocol    = "TCP"
        }
      }
      logs = {
        access = {
          enabled = true
        }
      }
      providers = {
        kubernetesCRD = {
          enabled = true
        }
        kubernetesIngress = {
          enabled = true
          publishedService = {
            enabled = true
          }
        }
      }
      #deployment:
      #  imagePullSecrets: ${image_pull_secrets_list}
      #  podAnnotations:
      #    prometheus.io/port: "8082"
      #    prometheus.io/scrape: "true"
      global = {
        systemDefaultRegistry = ""
      }
      service = {
        ipFamilyPolicy = "PreferDualStack"
      }
      tolerations = [
        {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        },
        {
          effect   = "NoSchedule"
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
        },
        {
          effect   = "NoSchedule"
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
        }
      ]
    })
  ]
}

resource "kubectl_manifest" "traefik-dashboard-certs" {
  depends_on = [
    helm_release.traefik
  ]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "traefik"
      namespace = kubernetes_namespace.traefik.metadata.0.name
    }
    spec = {
      commonName = local.traefik_dashboard.hostnames.0
      secretName = "traefik-dashboard"
      issuerRef = {
        name = "cluster-ca-issuer"
        kind = "ClusterIssuer"
      }
      dnsNames = local.traefik_dashboard.hostnames
    }
  })
}

resource "kubectl_manifest" "traefik-dashboard-ingress" {
  depends_on = [
    kubectl_manifest.traefik-dashboard-certs
  ]
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "traefik-dashboard"
      namespace = kubernetes_namespace.traefik.metadata.0.name
    }
    spec = {
      entryPoints = [
        "websecure"
      ]
      routes = [
        {
          match = join(" || ", [for h in local.traefik_dashboard.hostnames : "Host(`${h}`)"])
          kind = "Rule"
          services = [
            {
              name = "api@internal"
              kind = "TraefikService"
            }
          ]
        }
      ]
      tls = {
        secretName = "traefik-dashboard"
      }
    }
  })
}

resource "pihole_dns_record" "traefik-dashboard" {
  for_each = toset(local.traefik_dashboard.hostnames)
  domain = each.value
  ip     = local.kubernetes.ip
}