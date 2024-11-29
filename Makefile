.EXPORT_ALL_VARIABLES:

FRONTEND_DIR := frontend
BACKEND_DIR := backend
PYTHON := python3
JOBS ?= 4

.PHONY: all
all:
	@echo "Running with $(JOBS) parallel jobs..."
	$(MAKE) -j$(JOBS) fmt
	$(MAKE) -j$(JOBS) test

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
lint: lint-frontend lint-backend lint-yaml
	@echo "Linting completed for both frontend and backend."

.PHONY: fmt
fmt: fmt-frontend fmt-backend fmt-yaml
	@echo "Formatting completed for both frontend and backend."

.PHONY: fmt-check
fmt-check: fmt-frontend-check fmt-backend-check fmt-yaml-check
	@echo "Formatting check completed for both frontend and backend."

.PHONY: test
test: test-frontend test-backend
	@echo "Testing completed for both frontend and backend."

.PHONY: install-node
install-node:
	@if [ "$(shell uname)" = "Darwin" ]; then \
	  echo "Installing Node.js v20 on macOS..."; \
	  if ! command -v node > /dev/null; then \
	  	$(MAKE) -j$(JOBS) install-homebrew; \
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
install-node-react: install-node
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
	elif [ "$(shell uname -s)" = "Darwin" ]; then \
		echo "Installing gcloud for macOS..."; \
		$(MAKE) -j$(JOBS) install-homebrew; \
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
dev-requirements: install-node-react
	$(PYTHON) -m pip install yamllint pre-commit
	pre-commit install
