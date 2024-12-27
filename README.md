# terraform-aws-kube-lab
Module to setup a Kubernetes lab in AWS using kubeadm or EKS

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | ./modules/eks | n/a |
| <a name="module_kubeadm"></a> [kubeadm](#module\_kubeadm) | ./modules/kubeadm | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_allowed_cidrs"></a> [api\_allowed\_cidrs](#input\_api\_allowed\_cidrs) | A list of CIDRs granted access to the control plane API | `list(any)` | `[]` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | A name for various resources | `string` | `"kube-lab"` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `list(string)` | `[]` | no |
| <a name="input_control_plane_instance_type"></a> [control\_plane\_instance\_type](#input\_control\_plane\_instance\_type) | The instance type to use for control plane | `string` | `"t3.small"` | no |
| <a name="input_create_etcd_backups_bucket"></a> [create\_etcd\_backups\_bucket](#input\_create\_etcd\_backups\_bucket) | Set this to true to create a versioned and encrypted private bucket to store ETCD backups. | `bool` | `false` | no |
| <a name="input_eks_max_size"></a> [eks\_max\_size](#input\_eks\_max\_size) | Maximum number of nodes in EKS managed node group | `number` | `3` | no |
| <a name="input_eks_min_size"></a> [eks\_min\_size](#input\_eks\_min\_size) | Minimum number of nodes in EKS managed node group | `number` | `1` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | List of instance types to use in the managed node group | `list(string)` | `[]` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | The version of kubernets and associated tools to deploy | `string` | `"1.31.1-1.1"` | no |
| <a name="input_node_instance_type"></a> [node\_instance\_type](#input\_node\_instance\_type) | The instance type to use for nodes | `string` | `"t3.small"` | no |
| <a name="input_node_instances"></a> [node\_instances](#input\_node\_instances) | The number of nodes to launch. Max 3 | `number` | `2` | no |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | Private subnet IP ranges. | `list(any)` | <pre>[<br/>  "172.31.48.0/20",<br/>  "172.31.64.0/20",<br/>  "172.31.80.0/20"<br/>]</pre> | no |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | Public subnet IP ranges. | `list(any)` | <pre>[<br/>  "172.31.0.0/20",<br/>  "172.31.16.0/20",<br/>  "172.31.32.0/20"<br/>]</pre> | no |
| <a name="input_use_eks"></a> [use\_eks](#input\_use\_eks) | Create a managed EKS control plane and managed node group | `bool` | `false` | no |
| <a name="input_use_kubeadm"></a> [use\_kubeadm](#input\_use\_kubeadm) | Build cluster with kubeadm on EC2 instances | `bool` | `false` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC IP range. This should not overlap with the default for Weavenet, 10.32.0.0/12. | `string` | `"172.31.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_control_plane_id"></a> [control\_plane\_id](#output\_control\_plane\_id) | The control plane's instance id |
| <a name="output_control_plane_public_ip"></a> [control\_plane\_public\_ip](#output\_control\_plane\_public\_ip) | The control plane's public IP |
| <a name="output_etcd_backup_bucket"></a> [etcd\_backup\_bucket](#output\_etcd\_backup\_bucket) | S3 bucket to save ETCD backups to |
<!-- END_TF_DOCS -->
