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

publish-index:
	@PAR=$$(TF_LOG= $(OPENTOFU_CLI) output -show-sensitive -raw perf_results_upload_url); \
	META=$$(TF_LOG= $(OPENTOFU_CLI) output -json perf_results); \
	NS=$$(echo "$$META" | jq -r .namespace); \
	BUCKET=$$(echo "$$META" | jq -r .bucket_name); \
	REGION=$$(echo "$$META" | jq -r .region); \
	echo "uploading index.html…"; \
	curl -fSs -X PUT -H "Content-Type: text/html" -T index.html "$${PAR}index.html"; \
	echo; \
	echo "browse: https://$${NS}.objectstorage.$${REGION}.oci.customer-oci.com/n/$${NS}/b/$${BUCKET}/o/index.html"
