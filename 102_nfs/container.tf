resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "ssh_password" {
  length  = 32
  special = true
}

resource "proxmox_virtual_environment_container" "nfs" {
  description = "NFS storage provider"
  node_name   = local.homelab.node_name
  vm_id       = local.nfs.container_id

  features {
    mount = [
      "nfs"
    ]
  }

  # lifecycle {
  #   prevent_destroy = true
  # }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "ae:0b:9f:c1:fb:2c"
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_file.nfs.id
    type             = local.image_os
  }

  disk {
    datastore_id = "local-lvm"
    size         = 300 # gb
  }

  # disk {
  #   datastore_id = "local-lvm"
  #   size         = 1 # zfs ?
  # }

  # mount_point {
  #   # bind mount, *requires* root@pam authentication
  #   volume = "/mnt/bindmounts/shared"
  #   path   = "/mnt/shared"
  # }
  #
  # mount_point {
  #   # volume mount, a new volume will be created by PVE
  #   volume = "local-lvm"
  #   size   = "10G"
  #   path   = "/mnt/volume"
  # }

  initialization {
    hostname = "nfs-provider"

    ip_config {
      ipv4 {
        address = "${local.nfs.ip}/24"
        gateway = local.homelab.gateway
      }
    }

    user_account {
      keys = [
        trimspace(tls_private_key.ssh.public_key_openssh)
      ]
      password = random_password.ssh_password.result
      # username = local.nfs_username
    }
  }

  # connection {
  #   type        = "ssh"
  #   user        = local.nfs_username
  #   host        = var.config.ip
  #   private_key = tls_private_key.nfs.private_key_openssh
  # }

  # provisioner "file" {
  #   content = templatefile("${path.module}/configs/exports", {
  #     path = "/mnt"
  #     host = var.config.ip
  #   })
  #   destination = "/etc/exports"
  # }

  # provisioner "file" {
  #   content = templatefile("${path.module}/configs/ganesha.conf", {
  #     pseudo_path = "/"
  #     # host = var.config.ip
  #   })
  #   destination = "/etc/ganesha/ganesha.conf"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     # "apk add nfs-utils",
  #     # "mkdir -p /data",
  #     "exportfs -afv",
  #     # "rc-update add nfs",
  #     "rc-service nfs start"
  #   ]
  # }

  # provisioner "remote-exec" {
  #   connection {
  #     type        = "ssh"
  #     host        = var.cluster.ip
  #     user        = var.cluster.ssh_user
  #     private_key = var.cluster.ssh_key
  #   }
  #
  #   inline = [
  #     "apt install -y nfs-common"
  #   ]
  # }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = local.homelab.ip
      user     = split("@", local.homelab.ssh_username)[0]
      password = local.homelab.ssh_password
    }

    inline = [
      "echo 'lxc.apparmor.profile: unconfined' >> /etc/pve/lxc/${local.nfs.container_id}.conf",
      "lxc-stop --name ${local.nfs.container_id}",
      "sleep 5",
      "lxc-start --name ${local.nfs.container_id}"
      # "echo 'lxc.aa_profile: unconfined' >> /etc/vpe/lxc/${proxmox_virtual_environment_container.nfs.id}.conf"
      # lxc.apparmor.profile: unconfined
    ]
  }
}