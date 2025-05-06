terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
    remote = {
      source = "tmscer/remote"
    }
    ssh = {
      source = "loafoe/ssh"
    }
    pihole = {
      source  = "iolave/pihole"
      version = "0.2.2-beta.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      # version = "2.36.0"
    }
    k8s = {
      source  = "metio/k8s"
      # version = "2025.2.17"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      # version = "1.19.0"
    }
    helm = {
      source = "hashicorp/helm"
      }
  }
}

provider "proxmox" {
  endpoint = local.homelab.api_url
  insecure = true
  username = local.homelab.ssh_username
  password = local.homelab.ssh_password
}

provider "ssh" {}

provider "pihole" {
  url      = local.pihole.api_url
  password = local.pihole.web_password
  ca_file  = local.pihole.web_cert_file
}

provider "kubernetes" {
  config_path = local.kubernetes.kubeconfig
}

provider "kubectl" {
  config_path = local.kubernetes.kubeconfig
}

provider "helm" {
  kubernetes {
    config_path = local.kubernetes.kubeconfig
  }
}

provider "k8s" {
  kubeconfig = local.kubernetes.kubeconfig
}
