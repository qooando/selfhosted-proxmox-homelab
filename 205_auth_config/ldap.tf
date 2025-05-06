
locals {
  base_dn = join(",", formatlist("dc=%s", split(".", local.authentik.hostname)))
}

resource "authentik_stage_user_login" "ldap-authentication-login" {
  name                     = "ldap-authentication-login"
  terminate_other_sessions = false
}

data "authentik_flow" "default-password-change" {
  slug = "default-password-change"
}

resource "authentik_stage_password" "ldap-authentication-password" {
  name = "ldap-authentication-password"
  backends = [
    "authentik.core.auth.InbuiltBackend",
    "authentik.core.auth.TokenBackend",
    "authentik.sources.ldap.auth.LDAPBackend"
  ]
  configure_flow                = data.authentik_flow.default-password-change.id
  failed_attempts_before_cancel = 5
}

resource "authentik_stage_identification" "ldap-identification-stage" {
  name = "ldap-identification-stage"
  user_fields = [
    "username",
    "email"
  ]
  password_stage            = authentik_stage_password.ldap-authentication-password.id
  case_insensitive_matching = true
  show_matched_user         = true
  show_source_labels        = false
}

resource "authentik_flow" "ldap-authentication-flow" {
  designation        = "authentication"
  name               = "ldap-authentication-flow"
  slug               = "ldap-authentication-flow"
  title              = "LDAP Authentication Flow"
  authentication     = "require_unauthenticated"
  compatibility_mode = true
  denied_action      = "message_continue"
  policy_engine_mode = "any"
}

resource "authentik_flow_stage_binding" "ldap-identification-stage-bind" {
  order  = 10
  stage  = authentik_stage_identification.ldap-identification-stage.id
  target = authentik_flow.ldap-authentication-flow.uuid
}

resource "authentik_flow_stage_binding" "ldap-authentication-login-bind" {
  order  = 30
  stage  = authentik_stage_user_login.ldap-authentication-login.id
  target = authentik_flow.ldap-authentication-flow.uuid
}

data "authentik_flow" "default-invalidation-flow" {
  slug = "default-invalidation-flow"
}

resource "authentik_provider_ldap" "ldap" {
  name        = "default-ldap"
  base_dn     = local.base_dn
  bind_flow   = authentik_flow.ldap-authentication-flow.uuid
  unbind_flow = data.authentik_flow.default-invalidation-flow.id
}

data "authentik_users" "all" {
  depends_on = [
    authentik_user.users
  ]
}

resource "authentik_group" "ldap" {
  name  = "ldap"
  users = [for x in data.authentik_users.all.users : x.pk]
}

resource "authentik_outpost" "ldap" {
  name = "ldap"
  type = "ldap"
  protocol_providers = [
    authentik_provider_ldap.ldap.id
  ]
  service_connection = local.ldap.kubernetes_integration_id # kubernetes integration
}

resource "random_password" "ldap-automation" {
  length = 32
}

resource "authentik_user" "ldap-automation" {
  username = "ldap-automation"
  type     = "service_account"
  password = random_password.ldap-automation.result
}
