provider "aws" {
  region = "us-east-1"
}

module "kube_lab" {
  source = "../.."

  use_eks                      = true
  app_name                     = var.app_name
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  eks_min_size                 = 2
  eks_max_size                 = 3
  instance_types               = ["t3.micro"]
}
