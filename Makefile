# Rkub Makefile
export WORKERS         ?= 0
export MASTERS         ?= 1
export PROVIDER        ?= DO

export REGISTRY        ?= localhost:5000
export EE_IMAGE        ?= ee-rkub
export EE_TAG          ?= $(strip $(shell awk -F":" '/version/ {print $$2}' galaxy.yml | tr -d "[:blank:]"))
export EE_IMAGE_PATH   ?= $$HOME/$(EE_IMAGE)-$(EE_TAG)
export EE_PACKAGE_NAME ?= rke2_rancher_longhorn.zst
export EE_PACKAGE_PATH ?= $$HOME/$(EE_PACKAGE_NAME)

ifeq ($(PROVIDER), DO)
    USER_PRIVILEGED := root
    KEY_PATH := ./DO/infra/.key.private
    DO_SIZE_MATTERS ?= s-4vcpu-8gb
else ifeq ($(PROVIDER), AZ)
    USER_PRIVILEGED := terraform
    KEY_PATH := ./Azure/infra/.key.private
    AZ_SIZE_MATTERS ?= standard_d8s_v5
else
    $(error PROVIDER should be chosen between AZ or DO)
endif

.PHONY: prerequis
## Install required Ansible Collections
prerequis:
	$(MAKE) -C ./scripts/prerequis all

.PHONY: quickstart
## Create a RKE2 cluster on choosen cloud provider
quickstart:
ifeq ($(PROVIDER), DO)
	@$(MAKE) do_quickstart
else ifeq ($(PROVIDER), AZ)
	@$(MAKE) az_quickstart
else
	@echo "PROVIDER should be chosen between AZ or DO"
	@exit 1
endif

.PHONY: cleanup
## Cleanup RKE2 and VM from choosen cloud provider
cleanup:
ifeq ($(PROVIDER), DO)
	@$(MAKE) do_cleanup
else ifeq ($(PROVIDER), AZ)
	@$(MAKE) az_cleanup
else
	@echo "PROVIDER should be chosen between AZ or DO"
	@exit 1
endif

.PHONY: do_quickstart
## Create a RKE2 cluster on Digital Ocean
do_quickstart:
	# Checks vars settings
	@for v in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY DO_PAT; do \
	eval test -n \"\$$$$v\" || { echo "You must set environment variable $$v"; exit 1; } && echo $$v; \
	done
	# S3 bucket for Backend
	@cd ./test/DO/backend && terraform init
	@cd ./test/DO/backend && terraform plan -out=terraform.tfplan \
	  -var "token=$(DO_PAT)" \
	  -var "spaces_access_key_id=$(AWS_ACCESS_KEY_ID)" \
	  -var "spaces_access_key_secret=$(AWS_SECRET_ACCESS_KEY)"
	@cd ./test/DO/backend && terraform apply "terraform.tfplan"
	# Create infra with Terrafrom
	@cd ./test/DO/infra && terraform init -backend-config="bucket=terraform-backend-rkub-quickstart"
	@cd ./test/DO/infra && terraform plan -out=terraform.tfplan \
	  -var "token=$(DO_PAT)" \
	  -var "worker_count=$(WORKERS)" \
	  -var "controller_count=$(MASTERS)" \
	  -var "instance_size=$(DO_SIZE_MATTERS)" \
	  -var "spaces_access_key_id=$(AWS_ACCESS_KEY_ID)" \
	  -var "spaces_access_key_secret=$(AWS_SECRET_ACCESS_KEY)"
	@cd ./test/DO/infra && terraform apply "terraform.tfplan"
	# Wait cloud-init to finish
	@cd ./test && ANSIBLE_HOST_KEY_CHECKING=False ansible RKE2_CLUSTER -m shell -a "cloud-init status --wait" -u root -v
	# Run playbooks
	@cd ./test && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook playbooks/install.yml \
	  -u $(USER_PRIVILEGED) --private-key $(KEY_PATH) \
	  -e "stable=true" \
	  -e "airgap=false" \
	  -e "method=rpm"

.PHONY: az_quickstart
## Create a RKE2 cluster on Azure
az_quickstart:
	# Checks vars settings
	@for v in AZ_SUBS_ID AZ_CLIENT_ID AZ_CLIENT_SECRET AZ_TENANT_ID; do \
	eval test -n \"\$$$$v\" || { echo "You must set environment variable $$v"; exit 1; } && echo $$v; \
	done
	# Create infra with Terrafrom
	@for i in {1..2}; do \
	echo "Running command $$i time(s)"; \
	cd ./test/Azure/infra; \
	terraform init; \
	terraform plan -out=terraform.tfplan \
	  -var "azure_subscription_id=$(AZ_SUBS_ID)" \
	  -var "azure_client_id=$(AZ_CLIENT_ID)" \
	  -var "azure_client_secret=$(AZ_CLIENT_SECRET)" \
	  -var "azure_tenant_id=$(AZ_TENANT_ID)" \
	  -var "instance_size=$(AZ_SIZE_MATTERS)"; \
	terraform apply "terraform.tfplan"; \
	cd -; \
	done
	# Wait cloud-init to finish
	@cd ./test && ANSIBLE_HOST_KEY_CHECKING=False ansible RKE2_CLUSTER -m shell -a "cloud-init status --wait" -u root -v
	# Run playbooks
	@cd ./test && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook playbooks/install.yml \
	  -u $(USER_PRIVILEGED) --private-key $(KEY_PATH) \
	  -e "stable=true" \
	  -e "airgap=false" \
	  -e "method=rpm"


.PHONY: do_cleanup
## Remove RKE2 cluster from Digital Ocean
do_cleanup:
	# Checks vars settings
	@for v in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY DO_PAT; do \
	eval test -n \"\$$$$v\" || { echo "You must set environment variable $$v"; exit 1; } && echo $$v; \
	done
	# Delete infra with Terrafrom
	@cd ./test/DO/infra && terraform init -backend-config="bucket=terraform-backend-rkub-quickstart"
	@cd ./test/DO/infra && terraform plan -destroy -out=terraform.tfplan \
	  -var "token=$(DO_PAT)" \
	  -var "worker_count=$(WORKERS)" \
	  -var "controller_count=$(MASTERS)" \
	  -var "instance_size=$(DO_SIZE_MATTERS)" \
	  -var "spaces_access_key_id=$(AWS_ACCESS_KEY_ID)" \
	  -var "spaces_access_key_secret=$(AWS_SECRET_ACCESS_KEY)"
	@cd ./test/DO/infra && terraform apply "terraform.tfplan"
	# Remove S3 bucket for Backend
	@cd ./test/DO/backend && terraform init
	@cd ./test/DO/backend && terraform plan -destroy -out=terraform.tfplan \
	  -var "token=$(DO_PAT)" \
	  -var "spaces_access_key_id=$(AWS_ACCESS_KEY_ID)" \
	  -var "spaces_access_key_secret=$(AWS_SECRET_ACCESS_KEY)"
	@cd ./test/DO/backend && terraform apply "terraform.tfplan"

.PHONY: az_cleanup
## Remove RKE2 cluster from Azure
az_cleanup:
	# Checks vars settings
	@for v in AZ_SUBS_ID AZ_CLIENT_ID AZ_CLIENT_SECRET AZ_TENANT_ID; do \
	eval test -n \"\$$$$v\" || { echo "You must set environment variable $$v"; exit 1; } && echo $$v; \
	done
	# Create infra with Terrafrom
	@cd ./test/Azure/infra && terraform init
	@cd ./test/Azure/infra && terraform plan -destroy -out=terraform.tfplan \
	  -var "azure_subscription_id=${AZ_SUBS_ID}" \
	  -var "azure_client_id=${AZ_CLIENT_ID}" \
	  -var "azure_client_secret=${AZ_CLIENT_SECRET}" \
	  -var "azure_tenant_id=${AZ_TENANT_ID}" \
	  -var "instance_size=$(AZ_SIZE_MATTERS)"
	@cd ./test/Azure/infra && terraform apply "terraform.tfplan"

.PHONY: longhorn
## Install longhorn after quickstart on Digital Ocean
longhorn:
	@cd ./test && ansible-playbook playbooks/longhorn.yml -e "stable=true" -e "airgap=false" -u $(USER_PRIVILEGED) --private-key $(KEY_PATH)

.PHONY: rancher
## Install rancher after quickstart on Digital Ocean
rancher:
	@cd ./test && ansible-playbook playbooks/rancher.yml -e "stable=true" -e "airgap=false" -u $(USER_PRIVILEGED) --private-key $(KEY_PATH)

.PHONY: neuvector
## Install neuvector after quickstart on Digital Ocean
neuvector:
	@cd ./test && ansible-playbook playbooks/neuvector.yml -e "stable=true" -e "airgap=false" -u $(USER_PRIVILEGED) --private-key $(KEY_PATH)

.PHONY: build
## Run playbook to build rkub zst package on localhost.
build:
	ansible-playbook ./playbooks/build.yml

.PHONY: ee-container
## Create an execution-env container with all dependencies inside
ee-container:
	@printf "\e[1;34m[INFO]\e[m ## Build image $(EE_IMAGE_PATH) ##\n"
	podman build --platform linux/amd64 -f scripts/docker/Containerfile -t $(REGISTRY)/$(EE_IMAGE):$(EE_TAG) .
	podman save $(REGISTRY)/$(EE_IMAGE):$(EE_TAG) --format oci-archive -o $(EE_IMAGE_PATH)
	@printf "\e[1;32m[OK]\e[m Image $(REGISTRY)/$(EE_IMAGE):$(EE_TAG) builded and saved in $(EE_IMAGE_PATH).\n"

.PHONY: ee-exec
## Create a container with all dependencies inside.
ee-exec:
	@printf "\e[1;34m[INFO]\e[m ## Load image $(EE_IMAGE_PATH) ##\n"
	podman load -i $(EE_IMAGE_PATH)
	@printf "\e[1;32m[OK]\e[m Loaded.\n"
	@printf "\e[1;34m[INFO]\e[m ## Launch container - $(EE_IMAGE):$(EE_TAG) ##\n"
	podman run -it -v .:/rkub -v $(EE_PACKAGE_PATH):/root/$(EE_PACKAGE_NAME) $(REGISTRY)/$(EE_IMAGE):$(EE_TAG) '/bin/bash'


# keep it at the end of your Makefile
.DEFAULT_GOAL := show-help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
.PHONY: show-help
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| cat
