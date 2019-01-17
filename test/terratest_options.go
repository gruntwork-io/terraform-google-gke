package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func createGKEClusterTerraformOptions(
	t *testing.T,
	project string,
	region string,
	templatePath string,
) *terraform.Options {
	terraformVars := map[string]interface{}{
		"region":  region,
		"project": project,
	}

	terratestOptions := terraform.Options{
		TerraformDir: templatePath,
		Vars:         terraformVars,
	}

	return &terratestOptions

}

