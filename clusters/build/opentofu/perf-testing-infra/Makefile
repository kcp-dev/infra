OPENTOFU_CLI ?= tofu

init:
	$(OPENTOFU_CLI) init

fmt:
	$(OPENTOFU_CLI) fmt

plan:
	$(OPENTOFU_CLI) plan -var-file terraform.tfvars

apply:
	$(OPENTOFU_CLI) apply -var-file terraform.tfvars

endpoint:
	@TF_LOG= $(OPENTOFU_CLI) output -json perf_results

share:
	@TF_LOG= $(OPENTOFU_CLI) output -show-sensitive -raw perf_results_upload_url; echo
	@echo "expires: $$(TF_LOG= $(OPENTOFU_CLI) output -raw perf_results_upload_url_expires)"

rotate-share:
	$(OPENTOFU_CLI) apply -var-file terraform.tfvars -replace=oci_objectstorage_preauthrequest.perf_results_upload
