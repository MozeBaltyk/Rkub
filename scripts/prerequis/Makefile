export VERSION  ?= $(strip $(shell awk -F":" '/version/ {print $$2}' ../../galaxy.yml | tr -d "[:blank:]"))
export REPO     ?= $(strip $(shell awk -F" " '/repository/ {print $$2}' ../../galaxy.yml | tr -d "[:blank:]"))

ifneq ("$(wildcard /etc/redhat-release)","")
    PKG_MANAGER := yum
else ifneq ("$(wildcard /etc/debian_version)","")
    PKG_MANAGER := apt-get
endif

.PHONY: all
## all prerequisites (keep the phony order)
all: pythons bindeps collections arkade images

.PHONY: images
## Load images in files directories of each roles (since too big, those are in the .gitignore)
images:
	./podman-load.sh

.PHONY: arkade
## Install admin kubernetes commands
arkade:
	./arkade.sh

.PHONY: collections
## Install ansible collection defined in ./meta/ee-requirements.yml
collections:
	@printf "\e[1;34m[INFO]\e[m ## Install Ansible Collections dependencies ##\n"
	@ansible-galaxy install -r ../../meta/ee-requirements.yml
	@printf "\e[1;34m[INFO]\e[m ## Install $(REPO) version $(VERSION) ##\n"       
	@ansible-galaxy collection install git+$(REPO).git,$(VERSION)
	@printf "\e[1;32m[OK]\e[m Ansible Collections installed.\n"

.PHONY: pythons
## Install pythons packages defined in ./meta/ee-requirements.txt
pythons:
	@printf "\e[1;34m[INFO]\e[m ## Install Pip ##\n"
	@curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | python3
	@printf "\e[1;32m[OK]\e[m Pip installed.\n"
	@printf "\e[1;34m[INFO]\e[m ## Install Pip packages ##\n"
	@python3 -m pip install -r ../../meta/ee-requirements.txt
	@printf "\e[1;32m[OK]\e[m Pip packages installed.\n"

.PHONY: bindeps
## Install packages rpm/dep defined in ./meta/ee-bindeps.txt
bindeps:
	@printf "\e[1;34m[INFO]\e[m ## Install Bindeps package ##\n"
	@python3 -m pip install bindep
	@printf "\e[1;34m[INFO]\e[m ## Install Bindeps dependencies ##\n"
	@for i in $$( python3 -m bindep -bf ../../meta/ee-bindeps.txt ); do echo "### $$i ###"; sudo $(PKG_MANAGER) install -y $$i; done
	@printf "\e[1;32m[OK]\e[m All packages installed.\n"

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

