terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      # version = "2.36.0"
    }
  }
}

variable "namespace" {
  type = string
}

locals {
  private_registry_secret_configs = {
    "docker-hub-creds" : {
      server   = "https://index.docker.io/v1"
      username = "MISSING_USERNAME"
      password = "MISSING_PASSWORD"
      email    = "missing@ema.il"
    }
  }

  secret_names = tolist(keys(local.private_registry_secret_configs))
  pull_secrets = [
    for k in local.secret_names : { name : k }
  ]
}

resource "kubernetes_secret" "docker_registry" {
  for_each = tomap(local.private_registry_secret_configs)

  metadata {
    name      = each.key
    namespace = var.namespace
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      "auths" : {
        (each.value.server) : {
          "username" : each.value.username,
          "password" : each.value.password,
          "email" : each.value.email,
          "auth" : base64encode("${each.value.username}:${each.value.password}")
        }
      }
    })
  }
}

output "pull_secrets" {
  value = local.pull_secrets
}

output "secret_names" {
  value = local.secret_names
}