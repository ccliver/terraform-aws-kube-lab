provider "aws" {
  region = "us-east-2"
}

module "kube_lab" {
  source = "../.."

  ssh_public_key             = var.ssh_public_key
  ssh_allowed_cidrs          = var.ssh_allowed_cidrs
  create_etcd_backups_bucket = var.create_etcd_backups_bucket
}
