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

variable "api_allowed_cidrs" {
  type        = list(any)
  description = "A list of CIDRs granted access to the control plane API"
  default     = []
}

variable "kubernetes_version" {
  type        = string
  description = "The version of kubernets and associated tools to deploy"
  default     = "1.24.2-00"
}

variable "vpc_cidr" {
  type = string
  description = "VPC IP range. This should not overlap with the default for Weavenet, 10.32.0.0/12."
  default = "172.31.0.0/16"
}
