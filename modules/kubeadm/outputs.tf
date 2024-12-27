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
