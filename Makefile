HOST ?= debian-12
DEVEL_REQUIRED_DEB_PACKAGES = direnv make python3 docker.io ruby-mdl pre-commit
# https://github.com/sio/Makefile.venv
# Seamlessly manage Python virtual environment with a Makefile
Makefile.venv:
	curl \
		-o Makefile.fetched \
		-L "https://github.com/sio/Makefile.venv/raw/v2023.04.17/Makefile.venv"
	echo "fb48375ed1fd19e41e0cdcf51a4a0c6d1010dfe03b672ffc4c26a91878544f82 *Makefile.fetched" \
		| sha256sum --check - \
		&& mv Makefile.fetched Makefile.venv

include Makefile.venv

.PHONY: all
all: Makefile.venv $(VENV) install test


.PHONY: help
help: ## Display this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


.PHONY: install
install: Makefile.venv $(VENV)  ## Install requirements
	$(VENV)/pip install -r requirements.txt
	$(VENV)/ansible-galaxy install -r requirements.yml

.PHONY: devel
setup:  ## Set up development environment, install requirements for Debian Linux
	@echo "Going to install: $(DEVEL_REQUIRED_DEB_PACKAGES)"
	sudo apt-get install -y $(DEVEL_REQUIRED_DEB_PACKAGES)
	pre-commit install

.PHONY: create
create:  ## Start Molecule container
	$(VENV)/molecule create

.PHONY: converge
converge:  # Run ansible role on Molecule container
	$(VENV)/molecule converge

.PHONY: login
login:  ## Log into Molecule container. Default is `debian-12`
	$(VENV)/molecule login -h $(HOST)

.PHONY: test
test: install  ## Run tests using Molecule
	$(VENV)/molecule test

.PHONY: lint
lint: $(VENV) lint-yaml lint-ansible  ## Run all linters

.PHONY: lint-yaml
lint-yaml: install  ## Run yamllint
	$(VENV)/yamllint .

.PHONY: lint-ansible
lint-ansible: install ## Run ansiblelint
	$(VENV)/ansible-lint .

.PHONY: destroy
destroy:  ## Destroy molecule container
	$(VENV)/molecule destroy

.PHONY: trailing-spaces
trailing-spaces:
	$(shell find . -type f -name '*.yml' | xargs -n1 sed -i 's/[ \t]*$$//')

.PHONY: envrc
envrc: .envrc  ## Create local copy of .envrc

.envrc:
	cp .envrc.example .envrc
