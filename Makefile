# Rkub Makefile 

export INVENTORY       ?= ./plugins/inventory
export ANSIBLE_USER    ?= admin
export EXTRA_VARS      := $(shell for n in $$INSTALL_VARS; do echo "-e $$n "; done )
export OPT             ?=
export ANSIBLE_ARGS     = -i $(INVENTORY) -u $(ANSIBLE_USER) $(EXTRA_VARS) $(OPT)

export REGISTRY        ?= localhost:5000
export EE_IMAGE        ?= ee-rkub
export EE_TAG          ?= $(strip $(shell awk -F":" '/version/ {print $$2}' galaxy.yml | tr -d "[:blank:]"))
export EE_IMAGE_PATH   ?= $$HOME/$(EE_IMAGE)-$(EE_TAG)
export EE_PACKAGE_NAME ?= rke2_rancher_longhorn.zst
export EE_PACKAGE_PATH ?= $$HOME/$(EE_PACKAGE_NAME)

.PHONY: prerequis
## Install required Ansible Collections
prerequis:
	$(MAKE) -C ./scripts/prerequis all

.PHONY: build
## Run playbook to build rkub zst package on localhost.
build:
	ansible-playbook ./playbooks/tasks/build.yml $(ANSIBLE_ARGS)

.PHONY: upload
## Run playbook to upload rkub zst package.
upload:
	ansible-playbook ./playbooks/tasks/upload.yml $(ANSIBLE_ARGS)

.PHONY: install
## Run playbook to install rkub.
install:
	ansible-playbook ./playbooks/tasks/install.yml $(ANSIBLE_ARGS)

.PHONY: uninstall
## Run playbook to uninstall rkub.
uninstall:
	ansible-playbook ./playbooks/tasks/uninstall.yml $(ANSIBLE_ARGS)


##################
## EE Container ##
##################

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
