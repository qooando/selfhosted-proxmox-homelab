terraform {
  required_providers {
    pihole = {
      source  = "iolave/pihole"
      version = "0.2.2-beta.2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    k8s = {
      source = "metio/k8s"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    helm = {
      source = "hashicorp/helm"
    }
    skopeo = {
      source = "abergmeier/skopeo"
    }
  }
}

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
