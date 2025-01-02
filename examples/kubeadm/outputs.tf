output "control_plane_id" {
  description = "The control plane's instance id"
  value       = module.kube_lab.control_plane_id
}

output "control_plane_public_endpoint" {
  description = "The control plane's endpoint"
  value       = "https://${module.kube_lab.control_plane_public_ip}:6443"
}

output "etcd_backup_bucket" {
  description = "S3 bucket to save ETCD backups to"
  value       = module.kube_lab.etcd_backup_bucket
}

output "kubectl_cert_data_ssm_parameters" {
  description = "List of SSM Parameter ARNs containing cert data for kubectl config"
  value       = module.kube_lab.kubectl_cert_data_ssm_parameters
}
