.DEFAULT_GOAL := help


build: ## Deploy the lab
	terraform init -upgrade=true
	terraform apply -auto-approve

destroy: ## Destroy the lab environment
	terraform destroy -auto-approve

ssm_control_plane: ## SSH to the public IP of the control plane
	aws ssm start-session --target $(shell terraform output -json | jq -r .control_plane_id.value) --region us-east-1

get_ca_cert: ## Print kubectl CA cert
	@aws ssm get-parameter --region us-east-1 --name $(shell terraform output -json | jq -r .kubectl_cert_data_ssm_parameters.value[0]) --with-decryption | jq -r .Parameter.Value

get_client_cert: ## Print kubectl client cert
	@aws ssm get-parameter --region us-east-1 --name $(shell terraform output -json | jq -r .kubectl_cert_data_ssm_parameters.value[1]) --with-decryption | jq -r .Parameter.Value

get_client_key: ## Print kubectl client key
	@aws ssm get-parameter --region us-east-1 --name $(shell terraform output -json | jq -r .kubectl_cert_data_ssm_parameters.value[2]) --with-decryption | jq -r .Parameter.Value

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
