# Sample terraform-based deployable architecture with dependencies (extension)

This architecture extends another deployable architecture.

This solution is an "extension" type of deployable architecture, which requires other deployable architectures as prerequisites. You specify the type of deployable architecture and those prerequisites in the `ibm_catalog.json` file.

- The `install_type` for this deployable architecture is set to `extension`.
- The `dependencies` array identifies the prequisite deployable architectures.

In this solution, the dependency is on the [Sample terraform-based deployable architecture without dependencies](../tf-fullstack-da).

```json
"label": "Static website configurator",
"name": "static-website-configurator",
"install_type": "extension",
"working_directory": "solutions/tf-extension-da",
"dependencies": [
   {
      "flavors": [
         "replication"
      ],
      "id": "7df1e4ca-d54c-4fd0-82ce-3d13247308cd",
      "name": "deploy-arch-ibm-cos-config",
      "version": ">=v1.0.0"
   }
```

This solution configures the following infrastructure to host a static website:
- Public access for the provided Object Storage bucket
- The website configuration to host a static website.

![cos-website](../../reference-architectures/cos-website.svg)

:exclamation: This solution is not intended to be called by one or more other modules since they contain provider configurations, meaning they are not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers)

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.75.1 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [ibm_cos_bucket_website_configuration.website](https://registry.terraform.io/providers/ibm-cloud/ibm/1.75.1/docs/resources/cos_bucket_website_configuration) | resource |
| [ibm_iam_access_group_policy.policy](https://registry.terraform.io/providers/ibm-cloud/ibm/1.75.1/docs/resources/iam_access_group_policy) | resource |
| [ibm_iam_access_group.public_access_group](https://registry.terraform.io/providers/ibm-cloud/ibm/1.75.1/docs/data-sources/iam_access_group) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cos_bucket_crn"></a> [cos\_bucket\_crn](#input\_cos\_bucket\_crn) | The CRN of the Object Storage bucket to configure. | `string` | n/a | yes |
| <a name="input_cos_bucket_location"></a> [cos\_bucket\_location](#input\_cos\_bucket\_location) | The location of the Object Storage bucket. | `string` | n/a | yes |
| <a name="input_cos_bucket_name"></a> [cos\_bucket\_name](#input\_cos\_bucket\_name) | The name of the Object Storage bucket to configure. | `string` | n/a | yes |
| <a name="input_cos_instance_guid"></a> [cos\_instance\_guid](#input\_cos\_instance\_guid) | The GUID of the Object Storage instance to configure. | `string` | n/a | yes |
| <a name="input_error_document"></a> [error\_document](#input\_error\_document) | The name of the HTML file that exists in the bucket to use when a static website bucket error occurs. | `string` | `"error.html"` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud API key needed to deploy IAM-enabled resources. | `string` | n/a | yes |
| <a name="input_index_document"></a> [index\_document](#input\_index\_document) | The name of the HTML file that exists in the bucket to use as the home or default page of the website. | `string` | `"index.html"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_group_id"></a> [access\_group\_id](#output\_access\_group\_id) | Access group ID. |
| <a name="output_website_endpoint"></a> [website\_endpoint](#output\_website\_endpoint) | Website endpoint. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
