locals {
  image_path = "${path.module}/image/rootfs.tar.xz"
  image_os   = "alpine"
}

resource "null_resource" "image-check" {
  triggers = {
    hash = filesha512(local.image_path)
  }
}

resource "proxmox_virtual_environment_file" "image" {
  lifecycle {
    replace_triggered_by = [
      null_resource.image-check
    ]
  }
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = local.homelab.node_name
  # see http://download.proxmox.com/images/system/

  source_file {
    path      = local.image_path
    file_name = "pihole.tar.xz"
  }
}
