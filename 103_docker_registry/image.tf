resource "proxmox_virtual_environment_file" "docker-registry" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = local.homelab.node_name
  source_file {
    path      = "${path.module}/image/rootfs.tar.xz"
    file_name = "docker-registry.tar.xz"
  }
}

locals {
  image_os = "alpine"
}
