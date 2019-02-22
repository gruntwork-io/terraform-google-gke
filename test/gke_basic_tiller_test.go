package test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestGKEBasicTiller(t *testing.T) {
	t.Parallel()

	// Uncomment any of the following to skip that section during the test
	// os.Setenv("SKIP_create_test_copy_of_examples", "true")
	// os.Setenv("SKIP_create_terratest_options", "true")
	// os.Setenv("SKIP_terraform_apply", "true")
	// os.Setenv("SKIP_configure_kubectl", "true")
	// os.Setenv("SKIP_wait_for_workers", "true")
	// os.Setenv("SKIP_cleanup", "true")

	// - [x] Create GKE cluster
	// - [x] Configure kubectl
	// - [x] Securely install Helm using terraform-kubernetes-helm
	// - [ ] Install an example chart (nginx?)
	// - [ ] test port 80 open/running

	// Create a directory path that won't conflict
	workingDir := filepath.Join(".", "stages", t.Name())

	test_structure.RunTestStage(t, "create_test_copy_of_examples", func() {
		testFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
		logger.Logf(t, "path to test folder %s\n", testFolder)
		terraformModulePath := filepath.Join(testFolder, "gke-basic-tiller")
		test_structure.SaveString(t, workingDir, "gkeBasicTillerTerraformModulePath", terraformModulePath)
	})

	test_structure.RunTestStage(t, "create_terratest_options", func() {
		gkeBasicTillerTerraformModulePath := test_structure.LoadString(t, workingDir, "gkeBasicTillerTerraformModulePath")
		uniqueID := random.UniqueId()
		project := gcp.GetGoogleProjectIDFromEnvVar(t)
		region := gcp.GetRandomRegion(t, project, nil, nil)
		iamUser := getIAMUserFromEnv()
		gkeClusterTerratestOptions := createGKEClusterTerraformOptions(t, uniqueID, project, region, iamUser, gkeBasicTillerTerraformModulePath)
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

	test_structure.RunTestStage(t, "wait_for_workers", func() {
		verifyGkeNodesAreReady(t)
	})
}
