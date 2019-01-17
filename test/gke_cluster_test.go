package test

import (
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestGKECluster(t *testing.T) {
	t.Parallel()

	testFolder := test_structure.CopyTerraformFolderToTemp(t, "..", "examples")
	terraformModulePath := filepath.Join(testFolder, "gke-regional-public-cluster")

	project := "graphite-test-rileykarson"
	region := "us-central1"
	terratestOptions := createGKEClusterTerraformOptions(t, project, region, terraformModulePath)
	defer terraform.Destroy(t, terratestOptions)

	terraform.InitAndApply(t, terratestOptions)
}
