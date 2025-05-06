resource "authentik_application" "immich" {
  name              = "Immich"
  slug              = "immich"
  protocol_provider = authentik_provider_oauth2.immich.id
}

data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_property_mapping_provider_scope" "immich" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

resource "authentik_provider_oauth2" "immich" {
  name               = "Immich"
  client_id          = "immich"
  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "app.immich:///oauth-callback",
    },
    {
      matching_mode = "strict",
      url           = "https://${local.immich.hostname}/auth/login",
    },
    {
      matching_mode = "strict",
      url           = "https://${local.immich.hostname}/user-settings",
    }
  ]
  property_mappings = data.authentik_property_mapping_provider_scope.immich.ids
}


