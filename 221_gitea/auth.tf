resource "authentik_application" "gitea" {
  name              = "Gitea"
  slug              = "gitea"
  protocol_provider = authentik_provider_oauth2.gitea.id
}

data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_property_mapping_provider_scope" "gitea" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

resource "authentik_provider_oauth2" "gitea" {
  name               = "Gitea"
  client_id          = "gitea"
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "https://${local.gitea.hostname}/user/oauth2/authentik/callback",
    }
  ]
  property_mappings = data.authentik_property_mapping_provider_scope.gitea.ids
}


