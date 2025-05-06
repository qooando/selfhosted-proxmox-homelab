resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "helm_release" "cert-manager" {
  repository    = "https://charts.jetstack.io"
  name          = "cert-manager"
  chart         = "cert-manager"
  skip_crds     = false
  namespace     = kubernetes_namespace.cert-manager.metadata.0.name
  wait_for_jobs = true
  wait          = true

  values = [
    yamlencode({
      crds = {
        keep    = true
        enabled = true
      }
      enableCertificateOwnerRef = true
      # global = {
      #   imagePullSecrets = var.cluster.private_registry_secrets
      # }
    })
  ]
}


resource "kubernetes_secret" "proxmox-ca" {
  depends_on = [
    helm_release.cert-manager
  ]
  metadata {
    name      = "homelab-ca"
    namespace = kubernetes_namespace.cert-manager.metadata.0.name
  }
  data = {
    "tls.crt" = file(local.homelab.ca_cert)
    "tls.key" = file(local.homelab.ca_key)
  }
}

resource "kubectl_manifest" "proxmox-ca-issuer" {
  depends_on = [
    helm_release.cert-manager
  ]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "proxmox-ca-issuer"
      namespace = kubernetes_namespace.cert-manager.metadata.0.name
    }
    spec = {
      ca = {
        secretName = kubernetes_secret.proxmox-ca.metadata.0.name
      }
    }
  })
}

resource "kubectl_manifest" "cluster-ca" {
  depends_on = [
    helm_release.cert-manager
  ]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "cluster-ca"
      namespace = kubernetes_namespace.cert-manager.metadata.0.name
    }
    spec = {
      isCA       = true
      commonName = "*.${local.homelab.hostname}"
      dnsNames = [
        local.homelab.hostname,
        "*.${local.homelab.hostname}"
      ]
      secretName = "cluster-ca"
      privateKey = {
        algorithm = "ECDSA"
        size      = 256
      }
      issuerRef = {
        name  = "proxmox-ca-issuer"
        kind  = "Issuer"
        group = "cert-manager.io"
      }
    }
  })
  wait             = true
  wait_for_rollout = true
}

resource "kubectl_manifest" "cluster-ca-issuer" {
  depends_on = [
    helm_release.cert-manager
  ]
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "cluster-ca-issuer"
    }
    spec = {
      ca = {
        secretName = "cluster-ca"
      }
    }
  })
  wait             = true
  wait_for_rollout = true
}

data "kubernetes_secret" "cluster-ca" {
  depends_on = [
    kubectl_manifest.cluster-ca
  ]
  metadata {
    name      = "cluster-ca"
    namespace = kubernetes_namespace.cert-manager.metadata.0.name
  }
}
