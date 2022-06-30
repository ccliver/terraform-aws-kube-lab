variable "resource_name" {
  type        = string
  description = "A name for various resources"
  default     = "kube-lab"
}

variable "control_plane_instance_type" {
  type        = string
  description = "The instance type to use for control plane"
  default     = "t3.small"
}

variable "worker_instance_type" {
  type        = string
  description = "The instance type to use for worker nodes"
  default     = "t3.small"
}

variable "worker_instances" {
  type        = number
  description = "The number of worker nodes to launch"
  default     = 2
}

variable "ssh_public_key" {
  type        = string
  description = "The SSH public key to use on the instances (will also be used to create an EC2 Key Pair)"
}

variable "ssh_allowed_cidrs" {
  type        = list(any)
  description = "A list of CIDRs granted SSH access to the control plane and worker nodes"
  default     = []
}
