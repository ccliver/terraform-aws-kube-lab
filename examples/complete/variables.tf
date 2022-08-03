variable "ssh_allowed_cidrs" {
  description = "A list of CIDRs granted SSH access to the control plane and worker nodes"
  type        = list(any)
}

variable "create_etcd_backups_bucket" {
  type        = bool
  description = "Set this to true to create a versioned and encrypted private bucket to store ETCD backups."
  default     = false
}
