provider "aws" {
  region = "us-east-2"
}

module "kube_lab" {
  source = "../.."

  use_kubeadm                = true
  create_etcd_backups_bucket = var.create_etcd_backups_bucket
}
