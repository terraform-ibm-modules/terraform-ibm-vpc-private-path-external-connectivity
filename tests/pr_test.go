// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

// Use existing resource group
const resourceGroup = "geretain-test-resources"
const tfFullstackDADir = "solutions/tf-fullstack-da"

/*******************************************************************
* TESTS FOR THE TERRAFORM BASED FULLSTACK DEPLOYABLE ARCHITECTURE  *
*******************************************************************/
func TestRunTfFullstackDASchematics(t *testing.T) {
	t.Parallel()

	// Set up a schematics test
	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing:            t,
		TarIncludePatterns: []string{"*.tf", fmt.Sprintf("%s/*.tf", tfFullstackDADir)},
		TemplateFolder:     tfFullstackDADir,
		// This is the resource group that the workspace will be created in
		ResourceGroup:          resourceGroup,
		Prefix:                 "tf-full-da",
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})

	// Pass required variables
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		// use options.Prefix here to generate a unique prefix every time so resource group name is unique for every test
		{Name: "resource_group_name", Value: options.Prefix, DataType: "string"},
	}

	err := options.RunSchematicTest()
	assert.NoError(t, err, "Schematic Test had unexpected error")
}

func TestRunTfFullstackDAUpgrade(t *testing.T) {
	t.Parallel()

	// Set up upgrade test
	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:      t,
		TerraformDir: tfFullstackDADir,
		Prefix:       "tf-full-da-upg",
	})

	// Pass required variables (NOTE: ibmcloud_api_key is passed directly in test as TF_VAR so no need to include here)
	options.TerraformVars = map[string]interface{}{
		// use options.Prefix here to generate a unique prefix every time so resource group name is unique for every test
		"resource_group_name": options.Prefix,
	}

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}

/*******************************************************************
* TESTS FOR THE TERRAFORM BASED EXTENSION DEPLOYABLE ARCHITECTURE  *
*******************************************************************/

// TODO: Add tests
