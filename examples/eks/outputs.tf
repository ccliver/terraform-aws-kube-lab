output "kubeconfig_command" {
  description = "AWS CLI command to update local kubeconfig for EKS"
  value       = module.kube_lab.kubeconfig_command
}
