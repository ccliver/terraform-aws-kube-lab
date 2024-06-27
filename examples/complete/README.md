<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kube_lab"></a> [kube\_lab](#module\_kube\_lab) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_etcd_backups_bucket"></a> [create\_etcd\_backups\_bucket](#input\_create\_etcd\_backups\_bucket) | Set this to true to create a versioned and encrypted private bucket to store ETCD backups. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_control_plane_ip"></a> [control\_plane\_ip](#output\_control\_plane\_ip) | The control plane's IP |
| <a name="output_etcd_backup_bucket"></a> [etcd\_backup\_bucket](#output\_etcd\_backup\_bucket) | S3 bucket to save ETCD backups to |
| <a name="output_worker_1_ip"></a> [worker\_1\_ip](#output\_worker\_1\_ip) | The first worker node's IP |
| <a name="output_worker_2_ip"></a> [worker\_2\_ip](#output\_worker\_2\_ip) | The second worker node's IP |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
