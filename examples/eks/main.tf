provider "aws" {
  region = "us-east-2"
}

module "kube_lab" {
  source = "../.."

  use_eks                              = true
  app_name                             = var.app_name
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  eks_min_size                         = 2
  eks_max_size                         = 3
  kubernetes_version                   = "1.31"
  instance_types                       = ["t3.micro"]
}
