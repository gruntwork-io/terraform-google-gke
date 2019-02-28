package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func createGKEClusterTerraformOptions(
	t *testing.T,
	uniqueID,
	project string,
	region string,
	iamUser string,
	templatePath string,
) *terraform.Options {
	gkeClusterName := strings.ToLower(fmt.Sprintf("gke-cluster-%s", uniqueID))

	terraformVars := map[string]interface{}{
		"region":       region,
		"project":      project,
		"cluster_name": gkeClusterName,
		"iam_user":     iamUser,
		"tls_subject": map[string]string{
			"common_name": "tiller",
			"org":         "Gruntwork",
		},
		"client_tls_subject": map[string]string{
			"common_name": iamUser,
			"org":         "Gruntwork",
		},
		"force_undeploy":   true,
		"undeploy_release": true,
	}

	terratestOptions := terraform.Options{
		TerraformDir: templatePath,
		Vars:         terraformVars,
	}

	return &terratestOptions
}
