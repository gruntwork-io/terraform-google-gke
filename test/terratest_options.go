package test

import (
	"fmt"
	"strings"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func createTestGKEBasicHelmTerraformOptions(
	uniqueID,
	project string,
	region string,
	templatePath string,
	kubeConfigPath string,
) *terraform.Options {
	gkeClusterName := strings.ToLower(fmt.Sprintf("gke-cluster-%s", uniqueID))
	gkeServiceAccountName := strings.ToLower(fmt.Sprintf("gke-cluster-sa-%s", uniqueID))

	terraformVars := map[string]interface{}{
		"region":                       region,
		"location":                     region,
		"project":                      project,
		"cluster_name":                 gkeClusterName,
		"cluster_service_account_name": gkeServiceAccountName,
		"kubectl_config_path":          kubeConfigPath,
	}

	terratestOptions := terraform.Options{
		TerraformDir: templatePath,
		Vars:         terraformVars,
	}

	return &terratestOptions
}

func createTestGKEClusterTerraformOptions(
	uniqueID,
	project string,
	region string,
	templatePath string,
) *terraform.Options {
	gkeClusterName := strings.ToLower(fmt.Sprintf("gke-cluster-%s", uniqueID))
	gkeServiceAccountName := strings.ToLower(fmt.Sprintf("gke-cluster-sa-%s", uniqueID))

	terraformVars := map[string]interface{}{
		"region":                       region,
		"location":                     region,
		"project":                      project,
		"cluster_name":                 gkeClusterName,
		"cluster_service_account_name": gkeServiceAccountName,
	}

	terratestOptions := terraform.Options{
		TerraformDir: templatePath,
		Vars:         terraformVars,
	}

	return &terratestOptions
}
