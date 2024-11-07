output "control_plane_id" {
  description = "The control plane's instance id"
  value       = try(module.kubeadm[0].control_plane_id, null)
}

output "etcd_backup_bucket" {
  description = "S3 bucket to save ETCD backups to"
  value       = try(module.kubeadm[0].etcd_backup_bucket, null)
}

output "kubeconfig_command" {
  description = "AWS CLI command to update local kubeconfig for EKS"
  value       = try("aws eks update-kubeconfig --name ${var.app_name} --alias ${var.app_name} --region ${local.region}", null)
}
