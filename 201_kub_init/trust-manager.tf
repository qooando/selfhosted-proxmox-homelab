resource "helm_release" "trust-manager" {
  repository    = "https://charts.jetstack.io"
  name          = "trust-manager"
  chart         = "trust-manager"
  skip_crds     = false
  namespace     = kubernetes_namespace.cert-manager.metadata.0.name
  wait_for_jobs = true
  wait          = true
}

locals {
  ca-certificates-bundle-configmap-name = local.homelab.hostname
}

resource "kubectl_manifest" "ca-certificates-bundle" {
  depends_on = [
    helm_release.trust-manager
  ]
  yaml_body = yamlencode({
    apiVersion = "trust.cert-manager.io/v1alpha1"
    kind       = "Bundle"
    metadata = {
      name = local.ca-certificates-bundle-configmap-name
    }
    spec = {
      sources = [
        {
          useDefaultCAs = true
        },
        {
          secret = {
            name = data.kubernetes_secret.cluster-ca.metadata.0.name
            key  = "ca.crt"
          }
        },
        {
          secret = {
            name = kubernetes_secret.proxmox-ca.metadata.0.name
            key  = "tls.crt"
          }
        }
      ],
      target = {
        configMap = {
          key = "ca-certificates.crt"
        }
      }
    }
  })
}
