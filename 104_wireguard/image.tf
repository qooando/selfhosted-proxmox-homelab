resource null_resource "image-change" {
  triggers = {
    hash = filesha512("${path.module}/image/rootfs.tar.xz")
  }
}

resource "proxmox_virtual_environment_file" "wireguard" {
  depends_on = [
    null_resource.image-change
  ]
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = local.homelab.node_name
  source_file {
    path      = "${path.module}/image/rootfs.tar.xz"
    file_name = "wireguard.tar.xz"
  }
}

locals {
  image_os = "alpine"
}
