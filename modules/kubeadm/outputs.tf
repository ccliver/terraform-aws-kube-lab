output "control_plane_id" {
  description = "The control plane's instance id"
  value       = aws_instance.control_plane.id
}

output "control_plane_public_ip" {
  description = "The control plane's public IP"
  value       = aws_instance.control_plane.public_ip
}

output "etcd_backup_bucket" {
  description = "S3 bucket to save ETCD backups to"
  value       = try(aws_s3_bucket.etcd_backups[0].id, null)
}

output "kubectl_cert_data_ssm_parameters" {
  description = "List of SSM Parameter ARNs containing cert data for kubectl config"
  value = [
    aws_ssm_parameter.ca_cert.arn,
    aws_ssm_parameter.client_cert.arn,
    aws_ssm_parameter.client_key.arn
  ]
}
