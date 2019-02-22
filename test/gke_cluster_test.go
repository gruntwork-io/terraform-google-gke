package test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/shell"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestGKECluster(t *testing.T) {
	t.Parallel()

	// Uncomment any of the following to skip that section during the test
	// os.Setenv("SKIP_create_test_copy_of_examples", "true")
	// os.Setenv("SKIP_create_terratest_options", "true")
	// os.Setenv("SKIP_terraform_apply", "true")
	// os.Setenv("SKIP_configure_kubectl", "true")
	// os.Setenv("SKIP_wait_for_workers", "true")
	// os.Setenv("SKIP_cleanup", "true")

	// Create a directory path that won't conflict
	workingDir := filepath.Join(".", "stages", t.Name())

	test_structure.RunTestStage(t, "create_test_copy_of_examples", func() {
		testFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
		logger.Logf(t, "path to test folder %s\n", testFolder)
		terraformModulePath := filepath.Join(testFolder, "gke-regional-public-cluster")
		test_structure.SaveString(t, workingDir, "gkeClusterTerraformModulePath", terraformModulePath)
	})

	test_structure.RunTestStage(t, "create_terratest_options", func() {
		gkeClusterTerraformModulePath := test_structure.LoadString(t, workingDir, "gkeClusterTerraformModulePath")
		uniqueID := random.UniqueId()
		project := gcp.GetGoogleProjectIDFromEnvVar(t)
		region := gcp.GetRandomRegion(t, project, nil, nil)
		iamUser := getIAMUserFromEnv()
		gkeClusterTerratestOptions := createGKEClusterTerraformOptions(t, uniqueID, project, region, iamUser, gkeClusterTerraformModulePath)
		test_structure.SaveString(t, workingDir, "uniqueID", uniqueID)
		test_structure.SaveString(t, workingDir, "project", project)
		test_structure.SaveString(t, workingDir, "region", region)
		test_structure.SaveString(t, workingDir, "iamUser", iamUser)
		test_structure.SaveTerraformOptions(t, workingDir, gkeClusterTerratestOptions)
	})

	defer test_structure.RunTestStage(t, "cleanup", func() {
		gkeClusterTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.Destroy(t, gkeClusterTerratestOptions)
	})

	test_structure.RunTestStage(t, "terraform_apply", func() {
		gkeClusterTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		terraform.InitAndApply(t, gkeClusterTerratestOptions)
	})

	test_structure.RunTestStage(t, "configure_kubectl", func() {
		gkeClusterTerratestOptions := test_structure.LoadTerraformOptions(t, workingDir)
		project := test_structure.LoadString(t, workingDir, "project")
		region := test_structure.LoadString(t, workingDir, "region")
		clusterName := gkeClusterTerratestOptions.Vars["cluster_name"].(string)

		// gcloud beta container clusters get-credentials example-cluster --region australia-southeast1 --project dev-sandbox-123456
		cmd := shell.Command{
			Command: "gcloud",
			Args:    []string{"beta", "container", "clusters", "get-credentials", clusterName, "--region", region, "--project", project},
		}

		shell.RunCommand(t, cmd)
	})

	test_structure.RunTestStage(t, "wait_for_workers", func() {
		verifyGkeNodesAreReady(t)
	})
}
