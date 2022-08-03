output "control_plane_ip" {
  description = "The control plane's IP"
  value       = aws_instance.control_plane.public_ip
}

output "worker_1_ip" {
  description = "The first worker node's IP"
  value       = aws_instance.workers[0].public_ip
}

output "etcd_backup_bucket" {
  description = "S3 bucket to save ETCD backups to"
  value       = try(aws_s3_bucket.etcd_backups[0].id, null)
}
