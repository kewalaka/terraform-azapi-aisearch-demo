PROVIDER_SRC ?= /Users/stu.mace/.copilot/copilot-worktrees/kewalaka_terraform-provider-azapi/kewalaka-potential-train
PROVIDER_BIN_DIR ?= $(CURDIR)/.terraform-dev-providers
TF_CLI_CONFIG_FILE ?= $(CURDIR)/.terraformrc
TERRAFORM ?= terraform
GO ?= go
AZAPI_PROVIDER_ADDR ?= Azure/azapi
AZAPI_PROVIDER_BIN ?= terraform-provider-azapi

export TF_CLI_CONFIG_FILE

.PHONY: all build-provider terraformrc init validate fmt-check plan apply destroy clean

all: validate

build-provider:
	@test -d "$(PROVIDER_SRC)" || (echo "PROVIDER_SRC does not exist: $(PROVIDER_SRC)" >&2; exit 1)
	@mkdir -p "$(PROVIDER_BIN_DIR)"
	cd "$(PROVIDER_SRC)" && $(GO) build -o "$(PROVIDER_BIN_DIR)/$(AZAPI_PROVIDER_BIN)" .
	@chmod +x "$(PROVIDER_BIN_DIR)/$(AZAPI_PROVIDER_BIN)"

terraformrc: build-provider
	@printf '%s\n' 'provider_installation {' '  dev_overrides {' '    "$(AZAPI_PROVIDER_ADDR)" = "$(PROVIDER_BIN_DIR)"' '  }' '  direct {}' '}' > "$(TF_CLI_CONFIG_FILE)"
	@echo "Wrote $(TF_CLI_CONFIG_FILE)"

init: terraformrc
	$(TERRAFORM) init

validate: init
	$(TERRAFORM) validate

fmt-check:
	$(TERRAFORM) fmt -check -recursive

plan: init
	$(TERRAFORM) plan

apply: init
	$(TERRAFORM) apply

destroy: init
	$(TERRAFORM) destroy

clean:
	rm -rf .terraform .terraform.lock.hcl "$(TF_CLI_CONFIG_FILE)" "$(PROVIDER_BIN_DIR)"
