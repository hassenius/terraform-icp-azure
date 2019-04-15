package test

import (
	"testing"
	"os"
	"strings"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// An example of how to test the simple Terraform module in examples/terraform-basic-example using Terratest.
func TestTerraformICP(t *testing.T) {
	t.Parallel()

	// TODO: Tidy up this
	expectedText := "admin"

	// Get parameters for test
	terraformdir := os.Getenv("TEST_TFDIR")
	tfvars := strings.Split(os.Getenv("TEST_TFVARS"), ",")

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: terraformdir,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"example": expectedText,
			"instance_name": "hkterratest",
			"cluster_name": "hkterratest",
		},

		// Variables to pass to our Terraform code using -var-file options
		// VarFiles: []string{"terraform.tfvars"},
		VarFiles: tfvars,

		// Disable colors in Terraform commands so its easier to parse stdout/stderr
		NoColor: true,
	}

	// At the end of the test, run `terraform destroy` to clean up any resources that were created
	defer terraform.Destroy(t, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	actualTextExample := terraform.Output(t, terraformOptions, "ICP Admin Username")


	// Verify we're getting back the outputs we expect
	assert.Equal(t, expectedText, actualTextExample)
}
