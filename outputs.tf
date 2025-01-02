output "control_plane_id" {
  description = "The control plane's instance id"
  value       = try(module.kubeadm[0].control_plane_id, null)
}

output "control_plane_public_ip" {
  description = "The control plane's public IP"
  value       = try(module.kubeadm[0].control_plane_public_ip, null)
}

output "etcd_backup_bucket" {
  description = "S3 bucket to save ETCD backups to"
  value       = try(module.kubeadm[0].etcd_backup_bucket, null)
}

output "kubectl_cert_data_ssm_parameters" {
  description = "List of SSM Parameter ARNs containing cert data for kubectl config. This will only be populated if `var.use_kubeadm=true"
  value       = try(module.kubeadm[0].kubectl_cert_data_ssm_parameters, null)
}
