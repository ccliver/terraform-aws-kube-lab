variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet ids"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet ids"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.27`)"
  type        = string
  default     = null
}

variable "min_size" {
  type        = number
  description = "Minimum number of workers in EKS managed node group"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum number of workers in EKS managed node group"
  default     = 3
}

variable "cluster_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  default     = []
}

variable "instance_types" {
  type        = list(string)
  description = "List of instance types to use in the managed node group"
  default     = []
}
