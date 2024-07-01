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

# TODO: convert to ASG
variable "worker_instances" {
  type        = number
  description = "The number of worker nodes to launch. Max 3"
  default     = 2
}

variable "api_allowed_cidrs" {
  type        = list(any)
  description = "A list of CIDRs granted access to the control plane API"
  default     = []
}

variable "kubernetes_version" {
  type        = string
  description = "The version of kubernets and associated tools to deploy"
  default     = "1.29.6-1.1"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IP range. This should not overlap with the default for Weavenet, 10.32.0.0/12."
  default     = "172.31.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(any)
  description = "Public subnet IP ranges."
  default     = ["172.31.0.0/20", "172.31.16.0/20", "172.31.32.0/20"]
}

variable "private_subnet_cidrs" {
  type        = list(any)
  description = "Private subnet IP ranges."
  default     = ["172.31.48.0/20", "172.31.64.0/20", "172.31.80.0/20"]
}

variable "create_etcd_backups_bucket" {
  type        = bool
  description = "Set this to true to create a versioned and encrypted private bucket to store ETCD backups."
  default     = false
}
