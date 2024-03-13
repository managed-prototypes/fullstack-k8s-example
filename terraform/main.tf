terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.36"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://ams3.digitaloceanspaces.com"
    }
    # Note: Specified here, because function calls and variables are not allowed for this configuration
    key                         = "terraform/web-k8s/terraform.tfstate"
    bucket                      = "managed-prototypes"
    region                      = "us-east-1" # Note: Incorrect for DO, but the field is required by TF
    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }
}

provider "digitalocean" {
  token = var.do_pat
}

resource "random_id" "cluster_name" {
  byte_length = 5
}

locals {
  cluster_name = "tf-k8s-${random_id.cluster_name.hex}"
}

module "doks-cluster" {
  source = "./doks-cluster"

  do_pat = var.do_pat

  cluster_name    = local.cluster_name
  cluster_region  = "ams3"
  cluster_version = var.cluster_version

  worker_size  = var.worker_size
  worker_count = var.worker_count
}

module "kubernetes-config" {
  source = "./kubernetes-config"

  do_pat = var.do_pat

  cluster_name = module.doks-cluster.cluster_name
  cluster_id   = module.doks-cluster.cluster_id

  write_kubeconfig = var.write_kubeconfig
}
