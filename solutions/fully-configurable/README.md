# Cloud essentials for private-path external connectivity

## Description

This solution simplifies the deployment of Private Path services for VPC on IBM Cloud, pre-integrating them with the ability to connect to on-prem/external connections.

For more information about Private Path services for VPC please refer the [documentation](https://cloud.ibm.com/docs/vpc?topic=vpc-private-path-service-intro)

## Features and Capabilities

-  **on-prem connectivity**: Automates the provisioning of Application Load balancer with intgration to the Private-path Network Load balancer.

## Architecture

![Private Path services for VPC](https://raw.githubusercontent.com/terraform-ibm-modules/terraform-ibm-vpc-private-path-external-connectivity/blob/main/reference-architecture/private-path-external-connectivity.svg)

This architecture consists of:

-   **Private Path services for VPC**: Private Path services provide private connectivity for IBM Cloud and third-party services.
-   **Application Load balancer for VPC**: Application Load Balancer for VPC (ALB) to be attached as a member to the Private Path Network Load balancer.


<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | 1.78.2 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_private_path"></a> [private\_path](#module\_private\_path) | terraform-ibm-modules/vpc-private-path/ibm | 1.0.0 |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | terraform-ibm-modules/resource-group/ibm | 1.2.0 |

### Resources

| Name | Type |
|------|------|
| [ibm_is_lb.alb](https://registry.terraform.io/providers/ibm-cloud/ibm/1.78.2/docs/resources/is_lb) | resource |
| [ibm_is_lb_listener.alb_frontend_listener](https://registry.terraform.io/providers/ibm-cloud/ibm/1.78.2/docs/resources/is_lb_listener) | resource |
| [ibm_is_lb_pool.alb_backend_pool](https://registry.terraform.io/providers/ibm-cloud/ibm/1.78.2/docs/resources/is_lb_pool) | resource |
| [ibm_is_lb_pool_member.alb_pool_members](https://registry.terraform.io/providers/ibm-cloud/ibm/1.78.2/docs/resources/is_lb_pool_member) | resource |
| [ibm_is_vpc.vpc](https://registry.terraform.io/providers/ibm-cloud/ibm/1.78.2/docs/data-sources/is_vpc) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_loadbalancer_listener_certificate_instance"></a> [application\_loadbalancer\_listener\_certificate\_instance](#input\_application\_loadbalancer\_listener\_certificate\_instance) | The CRN of the certificate in your secret manager, it is applicable(mandatory) only to https protocol. | `string` | `null` | no |
| <a name="input_application_loadbalancer_listener_idle_timeout"></a> [application\_loadbalancer\_listener\_idle\_timeout](#input\_application\_loadbalancer\_listener\_idle\_timeout) | The protocol used to send traffic to instances in the pool. Supported values are `tcp`, `http`, `https` or `udp`. | `number` | `50` | no |
| <a name="input_application_loadbalancer_listener_port"></a> [application\_loadbalancer\_listener\_port](#input\_application\_loadbalancer\_listener\_port) | The listener port for the private path netwrok load balancer. | `number` | `80` | no |
| <a name="input_application_loadbalancer_listener_protocol"></a> [application\_loadbalancer\_listener\_protocol](#input\_application\_loadbalancer\_listener\_protocol) | The protocol used to send traffic to instances in the pool. Supported values are `tcp`, `http`, `https` or `udp`. | `string` | `"http"` | no |
| <a name="input_application_loadbalancer_pool_algorithm"></a> [application\_loadbalancer\_pool\_algorithm](#input\_application\_loadbalancer\_pool\_algorithm) | The load-balancing algorithm for private path netwrok load balancer pool members. Supported values are `round_robin` or `weighted_round_robin`. | `string` | `"round_robin"` | no |
| <a name="input_application_loadbalancer_pool_health_delay"></a> [application\_loadbalancer\_pool\_health\_delay](#input\_application\_loadbalancer\_pool\_health\_delay) | The interval between 2 consecutive health check attempts. The default is 5 seconds. Interval must be greater than `network_loadbalancer_pool_health_timeout` value. | `number` | `5` | no |
| <a name="input_application_loadbalancer_pool_health_retries"></a> [application\_loadbalancer\_pool\_health\_retries](#input\_application\_loadbalancer\_pool\_health\_retries) | The maximum number of health check attempts made before an instance is declared unhealthy. The default is 2 failed health checks. | `number` | `2` | no |
| <a name="input_application_loadbalancer_pool_health_timeout"></a> [application\_loadbalancer\_pool\_health\_timeout](#input\_application\_loadbalancer\_pool\_health\_timeout) | The maximum time the system waits for a response from a health check request. The default is 2 seconds. | `number` | `2` | no |
| <a name="input_application_loadbalancer_pool_health_type"></a> [application\_loadbalancer\_pool\_health\_type](#input\_application\_loadbalancer\_pool\_health\_type) | The protocol used to send health check messages to instances in the pool. Supported values are `tcp` or `http`. | `string` | `"http"` | no |
| <a name="input_application_loadbalancer_pool_member_ip_address"></a> [application\_loadbalancer\_pool\_member\_ip\_address](#input\_application\_loadbalancer\_pool\_member\_ip\_address) | value | `list(string)` | `[]` | no |
| <a name="input_application_loadbalancer_pool_member_port"></a> [application\_loadbalancer\_pool\_member\_port](#input\_application\_loadbalancer\_pool\_member\_port) | The port where traffic is sent to the instance. | `number` | `80` | no |
| <a name="input_application_loadbalancer_pool_protocol"></a> [application\_loadbalancer\_pool\_protocol](#input\_application\_loadbalancer\_pool\_protocol) | The protocol used to send traffic to instances in the pool. Supported values are `tcp`, `http`, `https` or `udp`. | `string` | `"http"` | no |
| <a name="input_application_loadbalancer_type"></a> [application\_loadbalancer\_type](#input\_application\_loadbalancer\_type) | value | `string` | `"private"` | no |
| <a name="input_existing_resource_group_name"></a> [existing\_resource\_group\_name](#input\_existing\_resource\_group\_name) | The name of an existing resource group in which to provision the private path services in. | `string` | `"Default"` | no |
| <a name="input_existing_subnet_id"></a> [existing\_subnet\_id](#input\_existing\_subnet\_id) | The ID of an existing subnet. | `string` | `null` | no |
| <a name="input_existing_vpc_id"></a> [existing\_vpc\_id](#input\_existing\_vpc\_id) | The ID of an existing VPC. If the user provides only the `existing_vpc_id` the private path service will be provisioned in the first subnet. | `string` | `null` | no |
| <a name="input_ibmcloud_api_key"></a> [ibmcloud\_api\_key](#input\_ibmcloud\_api\_key) | The API key to use for IBM Cloud. | `string` | n/a | yes |
| <a name="input_network_loadbalancer_listener_accept_proxy_protocol"></a> [network\_loadbalancer\_listener\_accept\_proxy\_protocol](#input\_network\_loadbalancer\_listener\_accept\_proxy\_protocol) | If set to true, listener forwards proxy protocol information that are supported by load balancers in the application family. Default value is false. | `bool` | `false` | no |
| <a name="input_network_loadbalancer_listener_port"></a> [network\_loadbalancer\_listener\_port](#input\_network\_loadbalancer\_listener\_port) | The listener port for the private path netwrok load balancer. | `number` | `80` | no |
| <a name="input_network_loadbalancer_name"></a> [network\_loadbalancer\_name](#input\_network\_loadbalancer\_name) | The name of the private path netwrok load balancer. | `string` | `"pp-nlb"` | no |
| <a name="input_network_loadbalancer_pool_algorithm"></a> [network\_loadbalancer\_pool\_algorithm](#input\_network\_loadbalancer\_pool\_algorithm) | The load-balancing algorithm for private path netwrok load balancer pool members. Supported values are `round_robin` or `weighted_round_robin`. | `string` | `"round_robin"` | no |
| <a name="input_network_loadbalancer_pool_health_delay"></a> [network\_loadbalancer\_pool\_health\_delay](#input\_network\_loadbalancer\_pool\_health\_delay) | The interval between 2 consecutive health check attempts. The default is 5 seconds. Interval must be greater than `network_loadbalancer_pool_health_timeout` value. | `number` | `5` | no |
| <a name="input_network_loadbalancer_pool_health_monitor_port"></a> [network\_loadbalancer\_pool\_health\_monitor\_port](#input\_network\_loadbalancer\_pool\_health\_monitor\_port) | The port on which the load balancer sends health check requests. By default, health checks are sent on the same port where traffic is sent to the instance. | `number` | `80` | no |
| <a name="input_network_loadbalancer_pool_health_monitor_url"></a> [network\_loadbalancer\_pool\_health\_monitor\_url](#input\_network\_loadbalancer\_pool\_health\_monitor\_url) | If you select HTTP as the health check protocol, this URL is used to send health check requests to the instances in the pool. By default, this is the root path `/` | `string` | `"/"` | no |
| <a name="input_network_loadbalancer_pool_health_retries"></a> [network\_loadbalancer\_pool\_health\_retries](#input\_network\_loadbalancer\_pool\_health\_retries) | The maximum number of health check attempts made before an instance is declared unhealthy. The default is 2 failed health checks. | `number` | `2` | no |
| <a name="input_network_loadbalancer_pool_health_timeout"></a> [network\_loadbalancer\_pool\_health\_timeout](#input\_network\_loadbalancer\_pool\_health\_timeout) | The maximum time the system waits for a response from a health check request. The default is 2 seconds. | `number` | `2` | no |
| <a name="input_network_loadbalancer_pool_health_type"></a> [network\_loadbalancer\_pool\_health\_type](#input\_network\_loadbalancer\_pool\_health\_type) | The protocol used to send health check messages to instances in the pool. Supported values are `tcp` or `http`. | `string` | `"tcp"` | no |
| <a name="input_network_loadbalancer_pool_member_port"></a> [network\_loadbalancer\_pool\_member\_port](#input\_network\_loadbalancer\_pool\_member\_port) | The port where traffic is sent to the instance. | `number` | `80` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix to be added to all resources created by this solution. To skip using a prefix, set this value to null or an empty string. The prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It should not exceed 16 characters, must not end with a hyphen('-'), and can not contain consecutive hyphens ('--'). Example: wx-0205-private-path. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md) | `string` | n/a | yes |
| <a name="input_private_path_access_tags"></a> [private\_path\_access\_tags](#input\_private\_path\_access\_tags) | A list of access tags to apply to the private path service created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details | `list(string)` | `[]` | no |
| <a name="input_private_path_account_policies"></a> [private\_path\_account\_policies](#input\_private\_path\_account\_policies) | The account-specific connection request policies. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-vpc-private-path/tree/main/solutions/fully-configurable/DA_inputs.md#options-with-acc-policies). | <pre>list(object({<br/>    account       = string<br/>    access_policy = string<br/>  }))</pre> | `[]` | no |
| <a name="input_private_path_default_access_policy"></a> [private\_path\_default\_access\_policy](#input\_private\_path\_default\_access\_policy) | The policy to use for bindings from accounts without an explicit account policy. The default policy is set to Review all requests. Supported options are `permit`, `deny`, or `review`. | `string` | `"review"` | no |
| <a name="input_private_path_name"></a> [private\_path\_name](#input\_private\_path\_name) | The name of the Private Path service for VPC. | `string` | `"private-path"` | no |
| <a name="input_private_path_publish"></a> [private\_path\_publish](#input\_private\_path\_publish) | Set this variable to `true` to allows any account to request access to to the Private Path service. If need be, you can also unpublish where access is restricted to the account that created the Private Path service by setting this variable to `false`. | `bool` | `false` | no |
| <a name="input_private_path_service_endpoints"></a> [private\_path\_service\_endpoints](#input\_private\_path\_service\_endpoints) | The list of name for the service endpoint where you want to connect your Private Path service. Enter a maximum number of 10 unique endpoint names for your service. | `list(string)` | n/a | yes |
| <a name="input_private_path_tags"></a> [private\_path\_tags](#input\_private\_path\_tags) | Optional list of tags to be added to the private path service. | `list(string)` | `[]` | no |
| <a name="input_private_path_zonal_affinity"></a> [private\_path\_zonal\_affinity](#input\_private\_path\_zonal\_affinity) | When enabled, the endpoint service preferentially permits connection requests from endpoints in the same zone. Without zonal affinity, requests are distributed to all instances in any zone. | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | The region in which the VPC resources are provisioned. | `string` | n/a | yes |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
