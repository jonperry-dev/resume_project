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
	cd $(FRONTEND_DIR) && npm run prettier -- --write "src/**/*.{js,jsx,ts,tsx}"

.PHONY: fmt-frontend-check
fmt-frontend-check:
	@echo "Checking frontend formatting..."
	cd $(FRONTEND_DIR) && npm run prettier -- --check "src/**/*.{js,jsx,ts,tsx}"

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

.PHONY: lint
lint: lint-frontend lint-backend
	@echo "Linting completed for both frontend and backend."

.PHONY: fmt
fmt: fmt-frontend fmt-backend
	@echo "Formatting completed for both frontend and backend."

.PHONY: fmt-check
fmt-check: fmt-frontend-check fmt-backend-check
	@echo "Formatting check completed for both frontend and backend."

.PHONY: test 
test: test-frontend test-backend
	@echo "Testing completed for both frontend and backend."
