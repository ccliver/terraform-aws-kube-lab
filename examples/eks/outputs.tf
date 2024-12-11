output "kubeconfig_command" {
  description = "AWS CLI command to update local kubeconfig for EKS"
  value       = try("aws eks update-kubeconfig --name ${var.app_name} --alias ${var.app_name} --region us-east-1", null)
}
