terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
    }
  }
}

provider "authentik" {
  url   = "https://${local.authentik.hostname}"
  token = local.authentik.auth_token
}
