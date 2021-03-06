output "control_plane_ip" {
  description = "The control plane's IP"
  value       = aws_instance.control_plane.public_ip
}

output "worker_1_ip" {
  description = "The first worker node's IP"
  value       = aws_instance.workers[0].public_ip
}
