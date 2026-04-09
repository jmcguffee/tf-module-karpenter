.PHONY: init test test-unit fmt validate lint clean help

TERRAFORM := terraform
TEST_DIR   := tests/unit

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform and download providers
	$(TERRAFORM) init

fmt: ## Format all Terraform files
	$(TERRAFORM) fmt -recursive

validate: init ## Validate Terraform configuration
	$(TERRAFORM) validate

test-unit: init ## Run unit tests (no AWS credentials required)
	$(TERRAFORM) test -test-directory=$(TEST_DIR)

test: test-unit ## Run all tests (alias for test-unit)

lint: fmt validate ## Run fmt + validate

clean: ## Remove local Terraform cache
	rm -rf .terraform .terraform.lock.hcl
