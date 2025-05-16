# Sample terraform-based deployable architecture without dependencies (fullstack)

Unlike the [extension-type](../tf-extension-da/) deployable architecture, this solution is "fullstack" and has no dependencies on other deployable architectures. A fullstack-type deployable architecture deploys and end-to-end solution.

:information_source: **Tip:** This `fullstack` install type is different from a [deployable architecture stack](https://cloud.ibm.com/docs/secure-enterprise?topic=secure-enterprise-understand-module-da#what-is-da), which is an architecture built of two or more deployable architectures that are often linked with references and deployed in a particular sequence.

You specify the type of deployable architecture in the `ibm_catalog.json` file.

- The `install_type` for this deployable architecture is set to `fullstack`.


This solution provisions the following resources:
- A new resource group, if an existing one is not passed in.
- A global Cloud Object Storage instance.
- A primary source Object Storage bucket in a given region.
- A target Object Storage bucket where data is replicated.
- A replication rule to replicate everything from the source bucket to the target bucket.
- An IAM authorization policy for the replication between the buckets.

![cos-replication](../../reference-architectures/cos-replication.svg)

:exclamation: This solution is not intended to be called by one or more other modules since they contain provider configurations, meaning they are not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers)

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.75.1 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cos_buckets"></a> [cos\_buckets](#module\_cos\_buckets) | terraform-ibm-modules/cos/ibm//modules/buckets | 8.19.2 |
| <a name="module_cos_instance"></a> [cos\_instance](#module\_cos\_instance) | terraform-ibm-modules/cos/ibm | 8.19.2 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | terraform-ibm-modules/resource-group/ibm | 1.1.6 |

### Resources

| Name | Type |
|------|------|
| [ibm_cos_bucket_replication_rule.cos_replication_rule](https://registry.terraform.io/providers/ibm-cloud/ibm/1.75.1/docs/resources/cos_bucket_replication_rule) | resource |
| [ibm_iam_authorization_policy.policy](https://registry.terraform.io/providers/ibm-cloud/ibm/1.75.1/docs/resources/iam_authorization_policy) | resource |
| [ibm_iam_account_settings.iam_account_settings](https://registry.terraform.io/providers/ibm-cloud/ibm/1.75.1/docs/data-sources/iam_account_settings) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_add_bucket_name_suffix"></a> [add\_bucket\_name\_suffix](#input\_add\_bucket\_name\_suffix) | Whether to append a randomly generated 4-character string to the Object Storage bucket names. Set to `false` for full control over the names in the `cos_source_bucket_name` and `cos_target_bucket_name` inputs. | `bool` | `true` | no |
| <a name="input_cos_instance_name"></a> [cos\_instance\_name](#input\_cos\_instance\_name) | The name to use when creating the IBM Cloud Object Storage instance. If the `prefix` input is passed, it is added before this value, in the format `<prefix>-value`. | `string` | `"cos-instance"` | no |
| <a name="input_cos_source_bucket_name"></a> [cos\_source\_bucket\_name](#input\_cos\_source\_bucket\_name) | The globally unique name to use for the source Cloud Object Storage bucket. If the `add_bucket_name_suffix` input is set to `true`, a random 4-character string is appended to this name to help ensure that the bucket name is globally unique. If the `prefix` input is passed, it is added before this value, in the format `<prefix>-value`. | `string` | `"source-bucket"` | no |
| <a name="input_cos_source_bucket_region"></a> [cos\_source\_bucket\_region](#input\_cos\_source\_bucket\_region) | The region to provision the source Cloud Object Storage bucket. | `string` | `"us-south"` | no |
| <a name="input_cos_target_bucket_name"></a> [cos\_target\_bucket\_name](#input\_cos\_target\_bucket\_name) | The globally unique name to use for the target Cloud Object Storage bucket. If the `add_bucket_name_suffix` input is set to `true`, a random 4-character string is appended to this name to help ensure that the bucket name is globally unique. If the `prefix` input is passed, it is added before this value, in the format `<prefix>-value`. | `string` | `"target-bucket"` | no |
| <a name="input_cos_target_bucket_region"></a> [cos\_target\_bucket\_region](#input\_cos\_target\_bucket\_region) | The region to provision the target Cloud Object Storage bucket. | `string` | `"us-east"` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The IBM Cloud API key needed to deploy IAM-enabled resources. | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for all resources created by this solution. | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of a new or an existing resource group to provision resources to. If the `prefix` input is passed, it is added before this value, in the format `<prefix>-value`. | `string` | n/a | yes |
| <a name="input_use_existing_resource_group"></a> [use\_existing\_resource\_group](#input\_use\_existing\_resource\_group) | Whether to use an existing resource group. | `bool` | `false` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cos_instance_crn"></a> [cos\_instance\_crn](#output\_cos\_instance\_crn) | Object Storage instance CRN |
| <a name="output_cos_instance_guid"></a> [cos\_instance\_guid](#output\_cos\_instance\_guid) | Object Storage instance guid |
| <a name="output_cos_instance_id"></a> [cos\_instance\_id](#output\_cos\_instance\_id) | Object Storage instance id |
| <a name="output_cos_source_bucket_crn"></a> [cos\_source\_bucket\_crn](#output\_cos\_source\_bucket\_crn) | Object Storage source bucket crn |
| <a name="output_cos_source_bucket_id"></a> [cos\_source\_bucket\_id](#output\_cos\_source\_bucket\_id) | Object Storage source bucket id |
| <a name="output_cos_source_bucket_name"></a> [cos\_source\_bucket\_name](#output\_cos\_source\_bucket\_name) | Object Storage source bucket name |
| <a name="output_cos_source_bucket_s3_endpoint_direct"></a> [cos\_source\_bucket\_s3\_endpoint\_direct](#output\_cos\_source\_bucket\_s3\_endpoint\_direct) | Object Storage source direct endpoint |
| <a name="output_cos_source_bucket_s3_endpoint_private"></a> [cos\_source\_bucket\_s3\_endpoint\_private](#output\_cos\_source\_bucket\_s3\_endpoint\_private) | Object Storage source private endpoint |
| <a name="output_cos_source_bucket_s3_endpoint_public"></a> [cos\_source\_bucket\_s3\_endpoint\_public](#output\_cos\_source\_bucket\_s3\_endpoint\_public) | Object Storage source public endpoint |
| <a name="output_cos_target_bucket_crn"></a> [cos\_target\_bucket\_crn](#output\_cos\_target\_bucket\_crn) | Object Storage target bucket CRN |
| <a name="output_cos_target_bucket_id"></a> [cos\_target\_bucket\_id](#output\_cos\_target\_bucket\_id) | Object Storage target bucket ID |
| <a name="output_cos_target_bucket_name"></a> [cos\_target\_bucket\_name](#output\_cos\_target\_bucket\_name) | Object Storage target bucket name |
| <a name="output_cos_target_bucket_s3_endpoint_direct"></a> [cos\_target\_bucket\_s3\_endpoint\_direct](#output\_cos\_target\_bucket\_s3\_endpoint\_direct) | Object Storage target direct endpoint |
| <a name="output_cos_target_bucket_s3_endpoint_private"></a> [cos\_target\_bucket\_s3\_endpoint\_private](#output\_cos\_target\_bucket\_s3\_endpoint\_private) | Object Storage target private endpoint |
| <a name="output_cos_target_bucket_s3_endpoint_public"></a> [cos\_target\_bucket\_s3\_endpoint\_public](#output\_cos\_target\_bucket\_s3\_endpoint\_public) | Object Storage target public endpoint |
| <a name="output_resource_group_id"></a> [resource\_group\_id](#output\_resource\_group\_id) | Resource group ID |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
