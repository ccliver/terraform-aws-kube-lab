output "control_plane_id" {
  description = "The control plane's instance id"
  value       = try(module.kubeadm[0].control_plane_id, null)
}

output "etcd_backup_bucket" {
  description = "S3 bucket to save ETCD backups to"
  value       = try(module.kubeadm[0].etcd_backup_bucket, null)
}
