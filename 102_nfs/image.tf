resource "proxmox_virtual_environment_file" "nfs" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = local.homelab.node_name
  # see http://download.proxmox.com/images/system/
  source_file {
    path      = "${path.module}/image/rootfs.tar.xz"
    file_name = "nfs.tar.xz"
  }
}

locals {
  image_os = "alpine"
}
