locals {
  build_path = "../build"
  authentik = yamldecode(file("${local.build_path}/authentik.vars.yaml"))
  ldap = {
    kubernetes_integration_id = "e1b61f51-eb54-4b0b-a4d2-42f148242be3" # fix this
  }
}

