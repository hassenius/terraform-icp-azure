# Define build harness branch
BUILD_HARNESS_ORG = hans-moen
BUILD_HARNESS_BRANCH = azurecli

# Define the Azure template settings
export AZURE_RESOURCE_GROUP ?= $(TF_VAR_resource_group)

# Define the template and vars file used by the build-harness terraform module
TERRAFORM_DIR ?=
TERRAFORM_VARS_FILE ?=

# GITHUB_USER containing '@' char must be escaped with '%40'
GITHUB_USER := $(shell echo $(GITHUB_USER) | sed 's/@/%40/g')
GITHUB_TOKEN ?=

.PHONY: default
default:: init;

.PHONY: init\:
init::
ifndef GITHUB_USER
	$(info GITHUB_USER not defined)
	exit -1
endif
	$(info Using GITHUB_USER=$(GITHUB_USER))
ifndef GITHUB_TOKEN
	$(info GITHUB_TOKEN not defined)
	exit -1
endif
ifndef TERRAFORM_DIR
	$(info TERRAFORM_DIR not defined)
	exit -1
endif
	$(info Using TERRAFORM_DIR=$(TERRAFORM_DIR))
ifndef TERRAFORM_VARS_FILE
	$(info TERRAFORM_VARS_FILE not defined)
	exit -1
endif
	$(info Using TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE))

-include $(shell curl -so .build-harness -H "Authorization: token $(GITHUB_TOKEN)" -H "Accept: application/vnd.github.v3.raw" "https://raw.github.ibm.com/ICP-DevOps/build-harness/master/templates/Makefile.build-harness"; echo .build-harness)

.PHONY: validate-tf
## Validate a given terraform template directory without deploying
validate-tf:
	@$(SELF) -s terraform:validate TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE) TERRAFORM_DIR=$(TERRAFORM_DIR)


.PHONY: deploy-icp
## Deploy a given terraform template directory with a given terraform VARS file
deploy-icp:
	@$(SELF) -s terraform:apply TERRAFORM_VARS_FILE=$(TERRAFORM_VARS_FILE) TERRAFORM_DIR=$(TERRAFORM_DIR)

.PHONY: validate-icp
validate-icp:
	echo "This is where we should run some proper validation"

.PHONY: cleanup
## Delete a given Azure Resource Group
cleanup:
	@$(SELF) -s azure:cleanrg
	@$(SELF) -s azure:clean
