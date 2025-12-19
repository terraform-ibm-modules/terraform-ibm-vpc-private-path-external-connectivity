// Tests in this file are run in the PR pipeline
package test

import (
	"fmt"
	"log"
	"os"
	"strings"
	"testing"

	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const fullyConfigurableSolutionDir = "solutions/fully-configurable"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var (
	sharedInfoSvc      *cloudinfo.CloudInfoService
	permanentResources map[string]interface{}
)

// TestMain will be run before any parallel tests, used to set up a shared InfoService object to track region usage
// for multiple tests
func TestMain(m *testing.M) {
	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})

	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func setupFullyConfigurableOptions(t *testing.T, prefix string) (*testschematic.TestSchematicOptions, *terraform.Options) {

	// ------------------------------------------------------------------------------------------------------
	// Create SLZ VPC, resource group first
	// ------------------------------------------------------------------------------------------------------
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	// Programmatically determine region to use based on availability
	region, _ := testhelper.GetBestVpcRegion(val, "../common-dev-assets/common-go-assets/cloudinfo-region-vpc-gen2-prefs.yaml", "eu-de")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix":        prefix,
			"region":        region,
			"resource_tags": []string{"test-schematic"},
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp resources (SLZ VPC and Secrets Manager) failed")
		return nil, nil
	}

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Prefix:  prefix,
		TarIncludePatterns: []string{
			fullyConfigurableSolutionDir + "/*.*",
			"*.tf",
		},
		ResourceGroup:          terraform.Output(t, existingTerraformOptions, "resource_group_name"),
		TemplateFolder:         fullyConfigurableSolutionDir,
		Tags:                   []string{"test-schematic"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
		Region:                 region,
	})
	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "prefix", Value: prefix, DataType: "string"},
		{Name: "region", Value: terraform.Output(t, existingTerraformOptions, "region"), DataType: "string"},
		{Name: "existing_resource_group_name", Value: terraform.Output(t, existingTerraformOptions, "resource_group_name"), DataType: "string"},
		{Name: "existing_subnet_id", Value: terraform.Output(t, existingTerraformOptions, "existing_subnet_id"), DataType: "string"},
		{Name: "private_path_service_endpoints", Value: []string{"vpc-pps.dev.internal"}, DataType: "list(string)"},
		{Name: "application_loadbalancer_pool_member_ip_address", Value: []string{terraform.Output(t, existingTerraformOptions, "member_ip_address")}, DataType: "list(string)"},
		{Name: "private_cert_engine_config_root_ca_common_name", Value: fmt.Sprintf("%s%s", options.Prefix, ".com"), DataType: "string"},
		{Name: "private_cert_engine_config_template_name", Value: permanentResources["privateCertTemplateName"], DataType: "string"},
		{Name: "existing_secrets_manager_instance_crn", Value: permanentResources["secretsManagerCRN"], DataType: "string"},
	}

	return options, existingTerraformOptions
}

func TestRunFullyConfigurableInSchematics(t *testing.T) {
	t.Parallel()
	prefix := fmt.Sprintf("ce-pp-%s", strings.ToLower(random.UniqueId()))
	options, existingTerraformOptions := setupFullyConfigurableOptions(t, prefix)
	if options == nil || existingTerraformOptions == nil {
		t.Fatal("Failed to create agent schematic options (prerequisite Terraform deployment failed)")
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestRunUpgradeFullyConfigurable(t *testing.T) {
	t.Parallel()

	// Provision existing resources first
	prefix := fmt.Sprintf("pp-upg-%s", strings.ToLower(random.UniqueId()))
	options, existingTerraformOptions := setupFullyConfigurableOptions(t, prefix)

	if options == nil || existingTerraformOptions == nil {
		t.Fatal("Failed to create agent schematic options (prerequisite Terraform deployment failed)")
	}
	options.CheckApplyResultForUpgrade = true

	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.NoError(t, err, "Upgrade test should complete without errors")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestFullyConfigurableSolutionExistingResources(t *testing.T) {
	t.Parallel()

	// ------------------------------------------------------------------------------------
	// Create SLZ VPC, SM private cert, resource group first
	// ------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("cts-s-ext-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))
	tags := common.GetTagsFromTravis()

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	// Programmatically determine region to use based on availability
	region, _ := testhelper.GetBestVpcRegion(val, "../common-dev-assets/common-go-assets/cloudinfo-region-vpc-gen2-prefs.yaml", "eu-de")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix":                                prefix,
			"region":                                region,
			"resource_tags":                         tags,
			"existing_secrets_manager_instance_crn": permanentResources["secretsManagerCRN"],
			"certificate_template_name":             permanentResources["privateCertTemplateName"],
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)

	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {
		// ------------------------------------------------------------------------------------
		// Deploy Private path solution
		// ------------------------------------------------------------------------------------
		options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
			Testing:      t,
			TerraformDir: fullyConfigurableSolutionDir,
			// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
			ImplicitRequired: false,
			TerraformVars: map[string]interface{}{
				"prefix":                       prefix,
				"existing_resource_group_name": terraform.Output(t, existingTerraformOptions, "resource_group_name"),
				"region":                       terraform.Output(t, existingTerraformOptions, "region"),
				"application_loadbalancer_listener_certificate_crn": terraform.Output(t, existingTerraformOptions, "sm_private_cert_crn"),
				"existing_subnet_id":                              terraform.Output(t, existingTerraformOptions, "existing_subnet_id"),
				"existing_secrets_manager_instance_crn":           permanentResources["secretsManagerCRN"],
				"private_path_service_endpoints":                  []string{"vpc-pps.dev.internal"},
				"application_loadbalancer_pool_member_ip_address": []string{terraform.Output(t, existingTerraformOptions, "member_ip_address")},
				"provider_visibility":                             "public",
			},
		})
		output, err := options.RunTestConsistency()
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestAddonsDefaultConfiguration(t *testing.T) {
	t.Parallel()

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	// Programmatically determine region to use based on availability
	region, _ := testhelper.GetBestVpcRegion(val, "../common-dev-assets/common-go-assets/cloudinfo-region-vpc-gen2-prefs.yaml", "eu-de")

	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:   t,
		Prefix:    "pp-vpc",
		QuietMode: false, // Suppress logs except on failure
	})

	options.AddonConfig = cloudinfo.NewAddonConfigTerraform(
		options.Prefix,
		"deploy-arch-ibm-is-private-path-ext-conn",
		"fully-configurable",
		map[string]interface{}{
			"region":                         region,
			"secrets_manager_service_plan":   "trial",
			"private_path_service_endpoints": []string{"vpc-pps.dev.internal"},
		},
	)

	options.AddonConfig.Dependencies = []cloudinfo.AddonConfig{
		// The VPC must be created explicitly because it is disabled by default in the catalog configuration due to this issue(https://github.ibm.com/ibmcloud/content-catalog/issues/6057).
		{
			OfferingName:   "deploy-arch-ibm-slz-vpc",
			OfferingFlavor: "fully-configurable",
			Enabled:        core.BoolPtr(true),
			Inputs: map[string]interface{}{
				"region": region,
			},
		},
		//	use existing secrets manager instance to prevent hitting 20 trial instance limit in account
		{
			OfferingName:   "deploy-arch-ibm-secrets-manager",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"existing_secrets_manager_crn":         permanentResources["secretsManagerCRN"],
				"service_plan":                         "__NULL__", // no plan value needed when using existing SM
				"skip_secrets_manager_iam_auth_policy": true,       // since using an existing Secrets Manager instance, attempting to re-create auth policy can cause conflicts if the policy already exists
				"secret_groups":                        []string{}, // passing empty array for secret groups as default value is creating general group and it will cause conflicts as we are using an existing SM
			},
		},
		// Disable target / route creation to prevent hitting quota in account
		{
			OfferingName:   "deploy-arch-ibm-cloud-monitoring",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_metrics_routing_to_cloud_monitoring": false,
			},
		},
		{
			OfferingName:   "deploy-arch-ibm-activity-tracker",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_activity_tracker_event_routing_to_cloud_logs": false,
			},
		},
	}

	err := options.RunAddonTest()
	require.NoError(t, err)
}
