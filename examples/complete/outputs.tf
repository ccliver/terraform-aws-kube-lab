output "control_plane_id" {
  description = "The control plane's instance id"
  value       = module.kube_lab.control_plane_id
}

output "etcd_backup_bucket" {
  description = "S3 bucket to save ETCD backups to"
  value       = module.kube_lab.etcd_backup_bucket
}
