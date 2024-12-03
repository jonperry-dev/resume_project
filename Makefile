.EXPORT_ALL_VARIABLES:

FRONTEND_DIR := frontend
BACKEND_DIR := backend
PYTHON := python3
GCP_PROJECT_NAME := ResumeAI
GCP_CREDENTIALS := google-credentials.json
GCP_REGION := us-central1
GCP_REPOSITORY_NAME := resume-ai-docker-repo
GCP_PROJECT_ID := proud-portfolio-386621
SERVER_HOST_NAME := 0.0.0.0
SERVER_PORT := 8080
MODEL_DIR ?= Llama-3.2-3B-Instruct
DOCKER_FILE ?= server.Dockerfile
IMAGE_NAME ?= resumeai-service
TAG := latest
IMAGE_URI = $(GCP_REGION)-docker.pkg.dev/$(GCP_PROJECT_ID)/$(GCP_REPOSITORY_NAME)/$(IMAGE_NAME):$(TAG)

default: all

.PHONY: all
all:
	$(MAKE) $(MAKEFLAGS) fmt
	$(MAKE) $(MAKEFLAGS) test

.PHONY: lint-frontend
lint-frontend:
	@echo "Linting frontend..."
	cd $(FRONTEND_DIR) && npm run lint

.PHONY: fmt-frontend
fmt-frontend:
	@echo "Formatting frontend..."
	cd $(FRONTEND_DIR) && npm run fmt:fix

.PHONY: fmt-frontend-check
fmt-frontend-check:
	@echo "Checking frontend formatting..."
	cd $(FRONTEND_DIR) && npm run fmt:check

.PHONY: test-frontend
test-frontend:
	@echo "Running frontend tests..."
	cd $(FRONTEND_DIR) && npm run test

.PHONY: lint-backend
lint-backend:
	@echo "Linting backend..."
	cd $(BACKEND_DIR) && $(PYTHON) -m flake8 .

.PHONY: fmt-backend
fmt-backend:
	@echo "Formatting backend..."
	cd $(BACKEND_DIR) && $(PYTHON) -m black .

.PHONY: fmt-backend-check
fmt-backend-check:
	@echo "Checking backend formatting..."
	cd $(BACKEND_DIR) && $(PYTHON) -m black --check .

.PHONY: test-backend
test-backend:
	@echo "Running backend tests..."
	cd $(BACKEND_DIR) && $(PYTHON) -m pytest

.PHONY: lint-yaml
lint-yaml:
	@echo "Linting YAML files..."
	yamllint .

.PHONY: fmt-yaml-check
fmt-yaml-check:
	@echo "Checking YAML formatting..."
	npx prettier --check "**/*.yml" "**/*.yaml"

.PHONY: fmt-yaml
fmt-yaml:
	@echo "Formatting YAML files..."
	npx prettier --write "**/*.yml" "**/*.yaml"

.PHONY: lint
lint:
	$(MAKE) $(MAKEFLAGS) lint-frontend
	$(MAKE) $(MAKEFLAGS) lint-backend
	$(MAKE) $(MAKEFLAGS) lint-yaml
	@echo "Linting completed for both frontend and backend."

.PHONY: fmt
fmt: 
	$(MAKE) $(MAKEFLAGS) fmt-frontend
	$(MAKE) $(MAKEFLAGS) fmt-backend
	$(MAKE) $(MAKEFLAGS) fmt-yaml
	@echo "Formatting completed for both frontend and backend."

.PHONY: fmt-check
fmt-check:
	$(MAKE) $(MAKEFLAGS) fmt-frontend-check
	$(MAKE) $(MAKEFLAGS) fmt-backend-check
	$(MAKE) $(MAKEFLAGS) fmt-yaml-check
	@echo "Formatting check completed for both frontend and backend."

.PHONY: test
test: 
	$(MAKE) $(MAKEFLAGS) test-frontend
	$(MAKE) $(MAKEFLAGS) test-backend
	@echo "Testing completed for both frontend and backend."

.PHONY: install-node
install-node:
	@if [ "$(shell uname)" = "Darwin" ]; then \
	  echo "Installing Node.js v20 on macOS..."; \
	  if ! command -v node > /dev/null; then \
	  	$(MAKE) $(MAKEFLAGS) install-homebrew; \
	    brew install node@20; \
	    brew link --overwrite --force node@20; \
	  else \
	    echo "Node.js is already installed."; \
	  fi; \
	elif [ "$(shell uname)" = "Linux" ]; then \
	  echo "Installing Node.js v20 on Linux..."; \
	  if ! command -v node > /dev/null; then \
	    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
	    sudo apt-get install -y nodejs; \
	  else \
	    INSTALLED_VERSION=$$(node -v | grep -oE '[0-9]+'); \
	    if [ "$$INSTALLED_VERSION" -ne "20" ]; then \
	      echo "Updating Node.js to v20..."; \
	      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
	      sudo apt-get install -y nodejs; \
	    else \
	      echo "Node.js v20 is already installed."; \
	    fi; \
	  fi; \
	elif [[ "$(OS)" == "Windows_NT" ]]; then \
	  echo "Please install Node.js v20 manually on Windows. Visit https://nodejs.org/"; \
	else \
	  echo "Unsupported operating system. Please install Node.js v20 manually."; \
	  exit 1; \
	fi

.PHONY: install-node-react
install-node-react:
	$(MAKE) $(MAKEFLAGS) install-node
	@echo "Installing Node.js and React dependencies..."
	npm install --save react react-dom
	npm install --save-dev @types/react @types/react-dom typescript
	npm install --save-dev --save-exact prettier
	@echo "Node.js and React dependencies installed successfully."

.PHONY: install-gcloud
install-gcloud:
	@if [ "$(shell uname -s)" = "Linux" ]; then \
		echo "Installing gcloud for Linux..."; \
		sudo apt-get -y update && sudo apt-get -y upgrade \
		sudo apt-get -y install apt-transport-https ca-certificates gnupg curl \
		curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
		echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
		sudo apt-get update && sudo apt-get install google-cloud-cli \
	elif [ "$(shell uname -s)" = "Darwin" ]; then \
		echo "Installing gcloud for macOS..."; \
		curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-x86_64.tar.gz && \
		tar -xzf google-cloud-cli-darwin-x86_64.tar.gz && \
		./google-cloud-sdk/install.sh --quiet; \
	else \
		echo "Unsupported operating system. Please install gcloud manually from https://cloud.google.com/sdk/docs/install"; \
		exit 1; \
	fi
	@echo "Google Cloud SDK installation completed."

.PHONY: install-vault
install-vault:
	@if [ "$(shell uname -s)" = "Linux" ]; then \
		echo "Installing vault for Linux"; \
		sudo apt-get update; \
		sudo apt-get -y install gpg coreutils; \
		curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
		echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list; \
		sudo apt update && sudo apt install hcp -y; \
	elif [ "$(shell uname -s)" = "Darwin" ]; then \
		echo "Installing gcloud for macOS..."; \
		$(MAKE) $(MAKEFLAGS) install-homebrew; \
		brew tap hashicorp/tap; \
		brew install hashicorp/tap/hcp; \
	else \
		echo "Unsupported operating system. Please install gcloud manually from https://cloud.google.com/sdk/docs/install"; \
		exit 1; \
	fi
	@echo "Vault installation completed."

.PHONY: install-homebrew
install-homebrew:
	@echo "Checking if Homebrew is installed..."
	@if ! which brew >/dev/null 2>&1; then \
		echo "Homebrew is not installed. Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo "Homebrew installation completed."; \

	else \
		echo "Homebrew is already installed."; \
	fi
	if [ "$$(uname -m)" = "arm64" ]; then \
		BREW_PATH="/opt/homebrew/bin"; \
	else \
		BREW_PATH="/usr/local/bin"; \
	fi; \

	SHELL_NAME=$$(basename $$SHELL)

	if [ "$$SHELL_NAME" = "bash" ]; then \
		RC_FILE="~/.bashrc"; \
	elif [ "$$SHELL_NAME" = "zsh" ]; then \
		RC_FILE="~/.zshrc"; \
	else \
		RC_FILE="~/.profile"; \
	fi; \

	echo "Detected shell: $$SHELL_NAME. Updating $$RC_FILE..."
	echo "export PATH=$$BREW_PATH:\$$PATH" >> $$RC_FILE
	echo "Added Homebrew to PATH in $$RC_FILE."
	if ! echo $$PATH | grep -q "$$BREW_PATH"; then \
		export PATH=$$BREW_PATH:$$PATH; \
		echo "Homebrew path exported temporarily. No need to restart the terminal."; \
	fi


.PHONY: dev-requirements
dev-requirements:
	$(MAKE) $(MAKEFLAGS) install-vault
	$(MAKE) $(MAKEFLAGS) install-node-react
	$(MAKE) $(MAKEFLAGS) install-gcloud
	$(PYTHON) -m pip install yamllint pre-commit
	pre-commit install

.PHONY: gcp-credentials
gcp-credentials:
	hcp vault-secrets secrets open GCP_CREDENTIALS -o $$GCP_CREDENTIALS

.SILENT: gcp-login
.PHONY: gcp-login
gcp-login:
	if [ ! -f $(GCP_CREDENTIALS) ]; then \
        echo "$(GCP_CREDENTIALS) does not exist. Running make target..."; \
        $(MAKE) $(MAKEFLAGS) install-vault; \
		$(MAKE) $(MAKEFLAGS) install-gcloud; \
		$(MAKE) $(MAKEFLAGS) gcp-credentials; \
    fi
	gcloud auth login --cred-file=$$GCP_CREDENTIALS
	gcloud config set project $(shell hcp vault-secrets run env | grep GCP_PROJECT_ID | cut -d'=' -f2)

.PHONY: build-backend
build-backend:
	@echo "$(HF_TOKEN)" > /tmp/hf_token
	DOCKER_BUILDKIT=1 docker build \
		--secret id=hf_token,src=/tmp/hf_token \
		-f $(DOCKER_FILE) \
		-t $(IMAGE_NAME):$(TAG) \
		--build-arg HOST_NAME=$(SERVER_HOST_NAME) \
		--build-arg PORT=$(SERVER_PORT) \
		--build-arg BACKEND_DIR=$(BACKEND_DIR) \
		--build-arg MODEL_DIR=$(MODEL_DIR) \
		--build-arg RANK_API_KEY=$(RANK_API_KEY) \
		.
	rm /tmp/hf_token

.PHONY: build-frontend
build-frontend:
	@echo "REACT_APP_RANK_ENDPOINT=$(REACT_APP_RANK_ENDPOINT)" >> .env
	@echo "REACT_APP_RANK_API_KEY=$(REACT_APP_RANK_API_KEY)" >> .env
	docker build \
		-f $(DOCKER_FILE) \
		-t $(IMAGE_NAME):$(TAG) \
		--build-arg FRONTEND_DIR=$(FRONTEND_DIR) \
		.
	rm .env

.PHONY: gcp-deploy-backend
gcp-deploy-backend:
	$(MAKE) $(MAKEFLAGS) build-backend
	docker tag $(IMAGE_NAME) $(IMAGE_URI)
	docker push $(IMAGE_URI)

.PHONY: gcp-deploy-frontend
gcp-deploy-frontend:
	$(MAKE) $(MAKEFLAGS) build-frontend
	docker tag $(IMAGE_NAME) $(IMAGE_URI)
	docker push $(IMAGE_URI)
	gcloud run deploy $(IMAGE_NAME) \
		--image $(IMAGE_URI) \
		--region $(GCP_REGION) \
		--platform managed \
		--allow-unauthenticated