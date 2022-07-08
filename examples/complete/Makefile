.DEFAULT_GOAL := help

build: ## Deploy the lab
	terraform init -upgrade=true
	terraform apply -auto-approve

ssh_control_plane: ## SSH to the public IP of the control plane
	ssh ubuntu@$(shell terraform output -json | jq -r .control_plane_ip.value)

ssh_worker_one: ## SSH to the public IP of the first worker node
	ssh ubuntu@$(shell terraform output -json | jq -r .worker_1_ip.value)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
