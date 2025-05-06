resource "kubernetes_namespace" "kyverno" {
  metadata {
    name = "kyverno"
  }
}

resource "helm_release" "kyverno" {
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  name       = "kyverno"
  namespace  = kubernetes_namespace.kyverno.metadata.0.name
  wait       = true

  values = [
    yamlencode({

    })
  ]
}

resource "kubectl_manifest" "inject-ca-certificates-policy" {
  depends_on = [
    helm_release.kyverno,
    kubectl_manifest.ca-certificates-bundle
  ]
  yaml_body = yamlencode({
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "inject-ca-certificates"
    }
    spec = {
      rules = [
        {
          name = "add-ca-certificates"
          match = {
            all = [
              { resources = { kinds = ["Pod"] } }
            ]
          }
          mutate = {
            foreach = [
              {
                list = "request.object.spec.[initContainers, containers]"
                patchStrategicMerge = {
                  spec = {
                    containers = [
                      {
                        "(name)" = "*"
                        volumeMounts = [
                          {
                            name      = "etc-ssl-certs"
                            mountPath = "/etc/ssl/certs/ca-certificates.crt"
                            subPath   = "ca-certificates.crt"
                            readonly  = true
                          }
                        ]
                      }
                    ]
                    volumes = [
                      {
                        name = "etc-ssl-certs"
                        configMap = {
                          name = local.ca-certificates-bundle-configmap-name
                        }
                      }
                    ]
                  }
                }
              }
            ]
          }
        }
      ]
    }
  })
}