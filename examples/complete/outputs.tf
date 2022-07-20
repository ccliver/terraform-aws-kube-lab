output "control_plane_ip" {
  description = "The control plane's IP"
  value       = module.kube_lab.control_plane_ip
}

output "worker_1_ip" {
  description = "The first worker node's IP"
  value       = module.kube_lab.worker_1_ip
}
