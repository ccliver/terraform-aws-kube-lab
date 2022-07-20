variable "ssh_allowed_cidrs" {
  description = "A list of CIDRs granted SSH access to the control plane and worker nodes"
  type        = list(any)
}
