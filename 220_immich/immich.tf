resource "kubernetes_namespace" "immich" {
  metadata {
    name = "immich"
  }
}

resource "postgresql_database" "immich" {
  name              = "immich"
  # owner                  = "my_role"
  # template               = "template0"
  # lc_collate             = "C"
  connection_limit  = -1
  allow_connections = true
  # alter_object_ownership = true
}

resource "postgresql_extension" "pgvecto-rs" {
  name     = "vectors"
  database = postgresql_database.immich.name
  version  = "0.3.0"
}

resource "kubernetes_persistent_volume_claim" "immich-pvc" {
  wait_until_bound = true
  metadata {
    name      = "immich-pvc"
    namespace = kubernetes_namespace.immich.metadata.0.name
    annotations = {
      "nfs.io/storage-path" = "photos"
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

resource "helm_release" "immich" {
  depends_on = [
    kubernetes_persistent_volume_claim.immich-pvc,
    postgresql_database.immich,
    postgresql_extension.pgvecto-rs
  ]
  chart         = "oci://ghcr.io/immich-app/immich-charts/immich"
  name          = "immich"
  namespace     = kubernetes_namespace.immich.metadata.0.name
  wait          = true
  wait_for_jobs = true
  timeout       = 60

  values = [
    yamlencode({
      env = {
        # REDIS_HOSTNAME   = "${var.config.redis.hostname}.${var.config.namespace}.svc.cluster.local:${var.config.redis.port}"
        # DB_HOSTNAME      = "${var.config.postgres.hostname}.${var.config.namespace}.svc.cluster.local:${var.config.postgres.port}"
        REDIS_HOSTNAME           = local.redis.service_host
        REDIS_PORT               = local.redis.service_port
        REDIS_USERNAME           = local.redis.default_username
        REDIS_PASSWORD           = local.redis.default_password
        REDIS_DBINDEX            = local.immich.redis_dbindex
        DB_HOSTNAME              = local.postgres.service_host
        DB_PORT                  = local.postgres.service_port
        DB_USERNAME              = local.postgres.default_user
        DB_PASSWORD              = local.postgres.default_password
        DB_DATABASE_NAME         = postgresql_database.immich.name
        MACHINE_LEARNING_WORKERS = 0
        NODE_EXTRA_CA_CERTS      = "/etc/ssl/certs/ca-certificates.crt"
        # IMMICH_CONFIG_FILE       = "/usr/src/app/config.json"
      }
      immich = {
        persistence = {
          library = {
            existingClaim = kubernetes_persistent_volume_claim.immich-pvc.metadata.0.name
          }
        }
        configuration = {
          oauth = {
            autoLaunch                = false
            autoRegister              = true
            buttonText                = "Login with OAuth"
            clientId                  = authentik_provider_oauth2.immich.client_id
            clientSecret              = authentik_provider_oauth2.immich.client_secret
            enabled                   = true
            issuerUrl                 = "https://${local.authentik.hostname}/application/o/${authentik_application.immich.slug}/.well-known/openid-configuration"
            "scope"                   = "openid email profile",
            "signingAlgorithm"        = "HS256",
            "profileSigningAlgorithm" = "none",
            "storageLabelClaim"       = "preferred_username",
            # "mobileOverrideEnabled" = false,
            # "mobileRedirectUri" = "",
            # "storageQuotaClaim": "immich_quota"
            # "defaultStorageQuota": 0,
          }
        }
      }
      server = {
        enabled = true
        image = {
          # repository = module.immich_image.tag
          # repository = "ghcr.io/immich-app/immich-server"
        }
      }
      machine-learning = {
        enabled = false
      }
    })
  ]
}

resource "kubectl_manifest" "immich-ingress-cert" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "immich"
      namespace = kubernetes_namespace.immich.metadata.0.name
    }
    spec = {
      secretName = "immich"
      issuerRef = {
        name = local.kubernetes_init.cluster_issuer_name
        kind = "ClusterIssuer"
      }
      dnsNames = local.immich.hostnames
    }
  })
  wait = true
}

resource "kubectl_manifest" "immich-ingress" {
  depends_on = [
    kubectl_manifest.immich-ingress-cert
  ]
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "immich"
      namespace = kubernetes_namespace.immich.metadata.0.name
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          match = join(" || ", [for h in local.immich.hostnames : "Host(`${h}`)"])
          kind = "Rule"
          services = [
            {
              name = "immich-server"
              port = 2283
            }
          ]
        }
      ]
      tls = { secretName = "immich" }
    }
  })
}

resource "random_password" "admin-password" {
  length  = 32
  special = true
}

resource "null_resource" "immich-config" {
  depends_on = [
    kubectl_manifest.immich-ingress
  ]
  triggers = {
    init_hash = filesha512(local.immich.init_script)
  }
  provisioner "local-exec" {
    command = templatefile(local.immich.init_script, {
      url            = "https://${local.immich.hostnames.0}"
      admin_username = local.immich.admin_username
      admin_password = random_password.admin-password.result
    })
  }
}

resource "pihole_dns_record" "dns" {
  for_each = toset(local.immich.hostnames)
  domain = each.value
  ip     = local.kubernetes.ip
}
