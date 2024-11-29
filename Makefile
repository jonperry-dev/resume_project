.EXPORT_ALL_VARIABLES:

FRONTEND_DIR := frontend
BACKEND_DIR := backend
PYTHON := python3

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
	npx prettier --check "**/*.yml"

.PHONY: fmt-yaml
fmt-yaml:
	@echo "Formatting YAML files..."
	npx prettier --write "**/*.yml"

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
	@echo "Detecting operating system..."
	@if [ "$(shell uname)" = "Darwin" ]; then \
	  echo "Installing Node.js v20 on macOS..."; \
	  if ! command -v node > /dev/null; then \
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

.PHONY: dev-requirements
dev-requirements: install-node-react
	$(PYTHON) -m pip install yamllint
