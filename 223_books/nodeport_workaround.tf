resource "kubernetes_service" "calibre-workaround" {
  metadata {
    name      = "calibre-workaround"
    namespace = kubernetes_namespace.calibre.metadata.0.name
  }
  spec {
    type = "NodePort"
    selector = {
      app = "calibre"
    }
    port {
      port        = 8083
      target_port = 8083
      node_port   = 30083
    }
  }
}
