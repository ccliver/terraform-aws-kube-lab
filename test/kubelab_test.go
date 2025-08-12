package test

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestKubeLabKubeadm(t *testing.T) {
	appName := fmt.Sprintf("%s-%s", "kubeadm-test", strings.ToLower(random.UniqueId()))
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/kubeadm",
		Vars: map[string]interface{}{
			"app_name":                   appName,
			"create_etcd_backups_bucket": true,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	output := terraform.Output(t, terraformOptions, "control_plane_id")
	assert.NotNil(t, output)
	output = terraform.Output(t, terraformOptions, "etcd_backup_bucket")
	assert.NotNil(t, output)
}

func TestKubeLabEKS(t *testing.T) {
	appName := fmt.Sprintf("%s-%s", "eks-test", strings.ToLower(random.UniqueId()))
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/eks",
		Vars: map[string]interface{}{
			"app_name": appName,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	output := terraform.Output(t, terraformOptions, "kubeconfig_command")
	assert.Equal(t, output, fmt.Sprintf("aws eks update-kubeconfig --name %s --alias %s --region us-east-1", appName, appName))
}
