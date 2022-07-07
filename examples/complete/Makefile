.DEFAULT_GOAL := help

ssh_control_plane: ## SSH to the public IP of the control plane
	ssh ubuntu@$(shell terraform output -json | jq -r .control_plane_ip.value)

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
