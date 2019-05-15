package test

import (
	"errors"
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/retry"
	"github.com/stretchr/testify/assert"
)

// kubeWaitUntilNumNodes continuously polls the Kubernetes cluster until there are the expected number of nodes
// registered (regardless of readiness).
func kubeWaitUntilNumNodes(t *testing.T, kubectlOptions *k8s.KubectlOptions, numNodes int, retries int, sleepBetweenRetries time.Duration) {
	statusMsg := fmt.Sprintf("Wait for %d Kube Nodes to be registered.", numNodes)
	message, err := retry.DoWithRetryE(
		t,
		statusMsg,
		retries,
		sleepBetweenRetries,
		func() (string, error) {
			nodes, err := k8s.GetNodesE(t, kubectlOptions)
			if err != nil {
				return "", err
			}
			if len(nodes) != numNodes {
				return "", errors.New("Not enough nodes")
			}
			return "All nodes registered", nil
		},
	)
	if err != nil {
		logger.Logf(t, "Error waiting for expected number of nodes: %s", err)
		t.Fatal(err)
	}
	logger.Logf(t, message)
}

// Verify that all the nodes in the cluster reach the Ready state.
func verifyGkeNodesAreReady(t *testing.T, kubectlOptions *k8s.KubectlOptions) {
	kubeWaitUntilNumNodes(t, kubectlOptions, 3, 30, 10*time.Second)
	k8s.WaitUntilAllNodesReady(t, kubectlOptions, 30, 10*time.Second)
	readyNodes := k8s.GetReadyNodes(t, kubectlOptions)
	assert.Equal(t, len(readyNodes), 3)
}
