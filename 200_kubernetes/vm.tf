resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "ssh_password" {
  length  = 32
  special = true
}

resource "proxmox_virtual_environment_file" "ubuntu" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = local.homelab.node_name
  source_file {
    path = "${path.module}/image/noble-server-cloudimg-amd64.img"
  }
}

resource "proxmox_virtual_environment_vm" "master" {
  node_name   = local.homelab.node_name
  name        = "kub-master"
  description = "Kubernetes cluster"
  vm_id       = local.kubernetes.vm_id

  agent {
    enabled = false
  }

  stop_on_destroy = true

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    sockets = 2
    cores   = 2
    type    = "x86-64-v2-AES"
  }

  memory {
    dedicated = 10000
    floating  = 2048
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_file.ubuntu.id
    interface    = "scsi0"
    size         = 50
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "bc:24:11:91:02:4c"
  }

  operating_system {
    type = "l26"
  }

  tpm_state {
    version = "v2.0"
  }

  serial_device {}

  initialization {

    ip_config {
      ipv4 {
        address = "${local.kubernetes.ip}/24"
        gateway = local.homelab.gateway
      }
    }

    user_account {
      keys = [trimspace(tls_private_key.ssh.public_key_openssh)]
      password = random_password.ssh_password.result
      username = local.kubernetes.ssh_username
    }

    # dns {
    #
    # }
  }
}

resource "ssh_resource" "k3s-master" {
  depends_on = [
    proxmox_virtual_environment_vm.master
  ]

  host        = local.kubernetes.ip
  user        = local.kubernetes.ssh_username
  private_key = tls_private_key.ssh.private_key_openssh

  triggers = {
    hashes = jsonencode([
      "${path.module}/configs/k3s_config.yaml"
    ])
  }

  file {
    destination = "/etc/rancher/k3s/config.yaml"
    source      = "${path.module}/configs/k3s_config.yaml"
  }

  commands = [
    "mkdir -p /etc/rancher/k3s/",
    "curl -sfL https://get.k3s.io > k3s_install.sh",
    "sudo sh k3s_install.sh --disable=traefik",
    "until [ -e /etc/rancher/k3s/k3s.yaml ]; do sleep 1; done",
    "rm -f /etc/resolv.conf",
    "ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf",
    "echo 'source <(kubectl completion bash)' >>~/.bashrc"
  ]

}

data remote_file "kubeconfig" {
  depends_on = [
    proxmox_virtual_environment_vm.master,
    ssh_resource.k3s-master
  ]

  path = "/etc/rancher/k3s/k3s.yaml"

  conn {
    user        = local.kubernetes.ssh_username
    host        = local.kubernetes.ip
    private_key = tls_private_key.ssh.private_key_openssh
  }
}
