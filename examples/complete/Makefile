.DEFAULT_GOAL := help

TIMESTAMP := $(shell date +%s)
ETCD_BACKUP_COMMAND := ETCDCTL_KEY=/home/ubuntu/pki/apiserver-etcd-client.key \
	ETCDCTL_API=3 \
	ETCDCTL_CACERT=/home/ubuntu/pki/ca.crt \
	ETCDCTL_CERT=/home/ubuntu/pki/apiserver-etcd-client.crt \
	etcdctl snapshot save ./etcd-backup-${TIMESTAMP}

build: ## Deploy the lab
	terraform init -upgrade=true
	terraform apply -auto-approve

destroy: ## Destroy the lab environment
	terraform destroy -auto-approve

ssm_control_plane: ## SSH to the public IP of the control plane
	aws ssm start-session --target $(shell terraform output -json module_outputs  | jq -r .control_plane_id) --region us-east-2

backup_etcd: ## Create a backup of ETCD and copy it to the backup S3 bucket from the control plane
	aws ssm start-session --target $(shell terraform output -json module_outputs  | jq -r .control_plane_id) --region us-east-2
	scp ubuntu@$(shell terraform output -json | jq -r .control_plane_ip.value):etcd-backup-${TIMESTAMP} .

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
