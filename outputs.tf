output "control_plane_ip" {
  value = aws_instance.control_plane.public_ip
}

output "worker_1_ip" {
  value = aws_instance.workers[0].public_ip
}
