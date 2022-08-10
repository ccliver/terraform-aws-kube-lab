output "control_plane_ip" {
  description = "The control plane's IP"
  value       = module.kube_lab.control_plane_ip
}

output "worker_1_ip" {
  description = "The first worker node's IP"
  value       = module.kube_lab.worker_1_ip
}

output "worker_2_ip" {
  description = "The second worker node's IP"
  value       = module.kube_lab.worker_2_ip
}

output "etcd_backup_bucket" {
  description = "S3 bucket to save ETCD backups to"
  value       = module.kube_lab.etcd_backup_bucket
}
