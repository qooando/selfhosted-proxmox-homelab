resource "local_file" "homepage_yaml" {
  filename = "${local.build_path}/homepage.vars.yaml"
  content = yamlencode({
    hostnames = local.homepage.hostnames
  })
}