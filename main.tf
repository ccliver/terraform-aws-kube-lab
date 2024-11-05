locals {
  azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  name    = "${var.app_name}-vpc"
  cidr    = var.vpc_cidr
  azs = [
    local.azs[0],
    local.azs[1],
    local.azs[2]
  ]
  public_subnets             = var.public_subnet_cidrs
  private_subnets            = var.private_subnet_cidrs
  manage_default_network_acl = false

  vpc_tags = {
    Name = "${var.app_name}-vpc"
  }
}

module "kubeadm" {
  count = var.use_kubeadm ? 1 : 0

  source = "./modules/kubeadm"

  app_name                    = var.app_name
  vpc_id                      = module.vpc.vpc_id
  vpc_cidr                    = var.vpc_cidr
  control_plane_instance_type = var.control_plane_instance_type
  worker_instance_type        = var.worker_instance_type
  worker_instances            = var.worker_instances
  api_allowed_cidrs           = var.api_allowed_cidrs
  kubernetes_version          = var.kubernetes_version
  public_subnet_cidrs         = module.vpc.public_subnets_cidr_blocks
  public_subnets              = module.vpc.public_subnets
  private_subnet_cidrs        = module.vpc.private_subnets_cidr_blocks
  private_subnets             = module.vpc.private_subnets
  create_etcd_backups_bucket  = var.create_etcd_backups_bucket
}
