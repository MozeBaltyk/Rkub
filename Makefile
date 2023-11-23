# Example makefile with some dummy rules, imported by default during ansible_collection creation, 

export INVENTORY     ?= ./plugins/inventory
export ANSIBLE_USER  ?= localadmin
export INSTALL_USER  ?= $(ANSIBLE_USER)
export EXTRA_VARS    := $(shell for n in $$INSTALL_VARS; do echo "-e $$n "; done )
export OPT           ?=
export ANSIBLE_ARGS   = -i $(INVENTORY) -u $(ANSIBLE_USER) -e install_user="$(INSTALL_USER)" $(EXTRA_VARS) $(OPT)


.PHONY: prerequis
## Install required Ansible Collections
prerequis:
	$(MAKE) -C ./scripts/prerequis all

.PHONY: precheck
## Check all prerequisites regarding the typ of install and the given arguments
precheck:
	ansible-playbook ./playbooks/tasks/precheck.yml $(ANSIBLE_ARGS)

.PHONY: install
## Run playbook to install k3s from a finish and installed collection.
install:
	ansible-playbook ./playbooks/tasks/install.yml $(ANSIBLE_ARGS)

.PHONY: uninstall
## Run playbook to uninstall k3s.
uninstall:
	ansible-playbook ./playbooks/tasks/uninstall.yml $(ANSIBLE_ARGS)



######## More details Help #############
define HELP_MSG
## Define and export variables which are common to all the make commands:
export INSTALL_VARS='
global_version=1.0.0
global_install_dir=/opt
'

## Make commands and there options 
make prerequis
make precheck  [-e "ANSIBLE_USER=ansible"] [-e "INSTALL_USER=myself"] [-e "INVENTORY=../myInventoryPath"] [-e "OPT= -Kk"]
make install   [-e "ANSIBLE_USER=ansible"] [-e "INSTALL_USER=myself"] [-e "INVENTORY=../myInventoryPath"] [-e "OPT= -Kk"]
make uninstall [-e "ANSIBLE_USER=ansible"] [-e "INSTALL_USER=myself"] [-e "INVENTORY=../myInventoryPath"] [-e "OPT= -Kk"]
make install   [-e "ANSIBLE_USER=ansible"] [-e "INSTALL_USER=myself"] [-e "INVENTORY=../myInventoryPath"] [-e "OPT= -Kk"]

endef
export HELP_MSG

.PHONY: help
## Show more details options about commands
help:
	@echo "\n$$HELP_MSG"


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
