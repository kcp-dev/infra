OPENTOFU_CLI ?= tofu

init:
	$(OPENTOFU_CLI) init

fmt:
	$(OPENTOFU_CLI) fmt

plan:
	$(OPENTOFU_CLI) plan -var-file terraform.tfvars

apply:
	$(OPENTOFU_CLI) apply -var-file terraform.tfvars

kubeconfig:
	$(OPENTOFU_CLI) output -show-sensitive -json | jq -r '.cluster.value.kubeconfig' > kubeconfig
