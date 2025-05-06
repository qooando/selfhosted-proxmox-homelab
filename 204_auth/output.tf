resource "local_file" "vars_yaml" {
  filename = "${local.build_path}/authentik.vars.yaml"
  content = yamlencode({
    hostname            = local.authentik.hostname
    secret_key          = random_password.secure-key.result
    bootstrap_password  = random_password.bootstrap-admin.result
    public_url          = "https://${local.authentik.hostname}"
    service_hostname    = "authentik-server.${kubernetes_namespace.auth.metadata.0.name}"
    service_url         = "http://authentik-server.${kubernetes_namespace.auth.metadata.0.name}:80"
    boostrap_auth_token = random_password.bootstrap-token.result
    auth_token          = local.authentik.manual_auth_token
    namespace           = kubernetes_namespace.auth.metadata.0.name
  })
}
