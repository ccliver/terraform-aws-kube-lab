output "control_plane_id" {
  description = "The control plane's instance id"
  value       = module.kube_lab.control_plane_id
}

output "control_plane_public_ip" {
  description = "The control plane's public IP"
  value       = module.kube_lab.control_plane_public_ip
}

output "etcd_backup_bucket" {
  description = "S3 bucket to save ETCD backups to"
  value       = module.kube_lab.etcd_backup_bucket
}
