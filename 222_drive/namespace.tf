resource "kubernetes_namespace" "drive" {
  metadata {
    name = "drive"
  }
}

module "registry-secrets" {
  source    = "../modules/registry_secrets"
  namespace = kubernetes_namespace.drive.metadata.0.name
}