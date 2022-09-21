package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestKubeLab(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",
		Vars: map[string]interface{}{
			"ssh_public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1S0a15hyIDsMR8qABYjgJYXWz176B5NIPp0NQTFeK+Bcmbu0Z70R96x5VK4ubV6vvWUZH8zNU2MrFU9k/UZdEq/qSlAJB6Whg0I9wuw4oYKGbu3k622OLVAzbQ9N9cKMPENPtSjB3Ld/VPWhp6Bc9daMgHqNkmWp8n6KmjzsuDodERqWAI6m+RucFXBwQJXt7uNCCYfQZdWuqylviQoIndBt51tpCF3+/U4UPLsHpFNSHlZCT5059+l72j7yiywjf4BRTWx2KCeJLAd8PDgPRZ2iIeAUq22WA1tdMnZV9+CIL4dj+c/x9Y3LKPm9m7DV+kOki8+CdRDnUNq+KQzrf",
            "ssh_allowed_cidrs": []string{"172.31.0.0/16"},
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	output := terraform.Output(t, terraformOptions, "control_plane_ip")
	assert.NotNil(t, output)
}
