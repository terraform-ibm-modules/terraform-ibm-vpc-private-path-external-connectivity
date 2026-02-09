########################################################################################################################
# Common variables
########################################################################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The API key to use for IBM Cloud."
  sensitive   = true
}

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the resources. [Learn more](https://cloud.ibm.com/docs/account?topic=account-rgs&interface=ui#create_rgs) about how to create a resource group."
  default     = "Default"
}

variable "region" {
  type        = string
  description = "The region to provision all the resources in. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/region) about how to select different regions for different services."
  default     = "us-south"
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to null or an empty string. **Important:** If you are deploying a VPC using the VPC DA, changing the prefix after initial deployment will cause Terraform to plan destruction and recreation of VPC resources. Changing the prefix should be treated as provisioning a new VPC environment, not renaming existing VPC resources. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    # must not exceed 16 characters in length
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "private_path_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to the Private Path service."
  default     = []
}

variable "private_path_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the Private Path service created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details."
  default     = []
}

##############################################################################
# VPC Variables
##############################################################################

variable "existing_vpc_crn" {
  type        = string
  description = "CRN of the existing VPC in which the VPN infrastructure will be created. If the user provides only the `existing_vpc_crn`, the Private Path service will be provisioned in the first subnet."
  default     = null
  validation {
    condition     = var.existing_vpc_crn == null && var.existing_subnet_id == null ? false : true
    error_message = "A value for either `existing_vpc_crn` or `existing_subnet_id` should be passed."
  }
}

variable "existing_subnet_id" {
  description = "The ID of an existing subnet."
  type        = string
  default     = null
}

##############################################################################
# ALB Variables
##############################################################################

variable "application_loadbalancer_pool_member_ip_address" {
  type        = list(string)
  default     = []
  description = "List of IP address of the application load balancer pool members."
}

variable "application_loadbalancer_type" {
  type        = string
  default     = "private"
  description = "The type of the application load balancer. Supported values are `private`, `public`."
  validation {
    condition     = contains(["private", "public"], var.application_loadbalancer_type)
    error_message = "Invalid type of application load balancer. Allowed values are 'private', 'public'."
  }
}

variable "application_loadbalancer_pool_algorithm" {
  type        = string
  description = "The load-balancing algorithm for Private Path network load balancer pool members. Supported values are `round_robin` or `weighted_round_robin`."
  default     = "round_robin"

  validation {
    condition     = contains(["round_robin", "weighted_round_robin"], var.application_loadbalancer_pool_algorithm)
    error_message = "Invalid load-balancing algorithm. Allowed values are 'round_robin', 'weighted_round_robin'."
  }
}

variable "application_loadbalancer_pool_member_port" {
  type        = number
  description = "The port where traffic is sent to the instance."
  default     = 443
}

variable "application_loadbalancer_pool_health_delay" {
  type        = number
  description = "The interval between 2 consecutive health check attempts. The default is 5 seconds. Interval must be greater than `network_loadbalancer_pool_health_timeout` value."
  default     = 5
}

variable "application_loadbalancer_pool_health_retries" {
  type        = number
  description = "The maximum number of health check attempts made before an instance is declared unhealthy. The default is 2 failed health checks."
  default     = 2
}

variable "application_loadbalancer_pool_health_timeout" {
  type        = number
  description = "The maximum time the system waits for a response from a health check request. The default is 2 seconds."
  default     = 2
}

variable "application_loadbalancer_pool_health_type" {
  type        = string
  description = "The protocol used to send health check messages to instances in the pool. Supported values are `tcp`, `https`."
  default     = "https"
  validation {
    condition     = contains(["tcp", "https"], var.application_loadbalancer_pool_health_type)
    error_message = "Invalid protocol for health check. Allowed values are 'tcp', 'https'."
  }
}

variable "application_loadbalancer_pool_protocol" {
  type        = string
  description = "The protocol used to send traffic to instances in the pool. Supported values are `tcp`, `https` or `udp`."
  default     = "https"
  validation {
    condition     = contains(["tcp", "https", "udp"], var.application_loadbalancer_pool_protocol)
    error_message = "Invalid protocol for loadbalancer pool. Allowed values are 'tcp', 'https' or 'udp'."
  }
}

variable "application_loadbalancer_listener_port" {
  type        = number
  description = "The listener port for the Private Path network load balancer."
  default     = 443
}

variable "application_loadbalancer_listener_protocol" {
  type        = string
  description = "The listener protocol used by instances in the application loadbalancer pool. Supported values are `tcp`, `https` or `udp`."
  default     = "https"
  validation {
    condition     = contains(["tcp", "https", "udp"], var.application_loadbalancer_listener_protocol)
    error_message = "Invalid listener protocol for application loadbalancer. Allowed values are 'tcp', 'https' or 'udp'."
  }
}

variable "application_loadbalancer_listener_idle_timeout" {
  type        = number
  description = "The idle connection timeout of the listener in seconds."
  default     = 50
}

variable "application_loadbalancer_listener_certificate_crn" {
  type        = string
  description = "The CRN of existing secrets manager private certificate to use to create application loadbalancer listener. If the value is null, then new private certificate is created. [Learn more](https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-certificates&interface=ui)"
  default     = null

  validation {
    condition     = var.application_loadbalancer_listener_certificate_crn == null ? var.private_cert_engine_config_template_name != null && var.private_cert_engine_config_root_ca_common_name != null : true
    error_message = "Set 'private_cert_engine_config_root_ca_common_name' and 'private_cert_engine_config_template_name' input variables if a 'application_loadbalancer_listener_certificate_crn' input variable is not set"
  }

  validation {
    condition     = var.application_loadbalancer_listener_certificate_crn != null ? var.private_cert_engine_config_template_name == null && var.private_cert_engine_config_root_ca_common_name == null : true
    error_message = "'private_cert_engine_config_root_ca_common_name' and 'private_cert_engine_config_template_name' input variables can not be set if a 'application_loadbalancer_listener_certificate_crn' input variable is already set"
  }
}

##############################################################################
# Secrets Manager resources
##############################################################################

variable "existing_secrets_manager_instance_crn" {
  type        = string
  description = "The CRN of existing secrets manager where the certificate to use for the ALB listener is stored or where the new private certificate will be created. [Learn more](https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-getting-started)"
}

variable "existing_secrets_manager_secret_group_id" {
  type        = string
  description = "The ID of existing secrets manager secret group used for new created certificate. If the value is null, then new secrets manager secret group is created. [Learn more](https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-secret-groups&interface=ui)"
  default     = null
}

variable "private_cert_engine_config_root_ca_common_name" {
  type        = string
  description = "A fully qualified domain name or host domain name for the certificate to be created. Required if `application_loadbalancer_listener_certificate_crn` input variable is `null`. [Learn more](https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-private-certificates&interface=ui)"
  default     = null
}

variable "private_cert_engine_config_template_name" {
  type        = string
  description = "The name of the Certificate Template to create for a private certificate secret engine. When `application_loadbalancer_listener_certificate_crn` input variable is `null`, then it has to be the existing template name that exists in the private cert engine. [Learn more](https://cloud.ibm.com/docs/secrets-manager?topic=secrets-manager-private-certificates&interface=ui)"
  default     = null
}

##############################################################################
# NLB Variables
##############################################################################

variable "network_loadbalancer_name" {
  type        = string
  description = "The name of the Private Path network load balancer."
  default     = "pp-nlb"
}

variable "network_loadbalancer_listener_port" {
  type        = number
  description = "The listener port for the Private Path network load balancer."
  default     = 443
}

variable "network_loadbalancer_listener_accept_proxy_protocol" {
  type        = bool
  description = "If set to true, listener forwards proxy protocol information that are supported by load balancers in the application family. Default value is false."
  default     = false
}

variable "network_loadbalancer_pool_algorithm" {
  type        = string
  description = "The load-balancing algorithm for Private Path network load balancer pool members. Supported values are `round_robin` or `weighted_round_robin`."
  default     = "round_robin"
}

variable "network_loadbalancer_pool_health_delay" {
  type        = number
  description = "The interval between 2 consecutive health check attempts. The default is 5 seconds. Interval must be greater than `network_loadbalancer_pool_health_timeout` value."
  default     = 5
}

variable "network_loadbalancer_pool_health_retries" {
  type        = number
  description = "The maximum number of health check attempts made before an instance is declared unhealthy. The default is 2 failed health checks."
  default     = 2
}

variable "network_loadbalancer_pool_health_timeout" {
  type        = number
  description = "The maximum time the system waits for a response from a health check request. The default is 2 seconds."
  default     = 2
}

variable "network_loadbalancer_pool_health_type" {
  type        = string
  description = "The protocol used to send health check messages to instances in the pool. Supported values are `tcp` or `https`."
  default     = "tcp"
  validation {
    condition     = contains(["tcp", "https"], var.network_loadbalancer_pool_health_type)
    error_message = "Invalid network loadbalancer health type. Allowed values are 'tcp', 'https'."
  }
}

variable "network_loadbalancer_pool_health_monitor_url" {
  type        = string
  description = "If you select HTTP as the health check protocol, this URL is used to send health check requests to the instances in the pool. By default, this is the root path `/`"
  default     = "/"
}

variable "network_loadbalancer_pool_health_monitor_port" {
  type        = number
  description = "The port on which the load balancer sends health check requests. By default, health checks are sent on the same port where traffic is sent to the instance."
  default     = 443
}

variable "network_loadbalancer_pool_member_port" {
  type        = number
  description = "The port where traffic is sent to the instance."
  default     = 443
}

##############################################################################
# Private Path Variables
##############################################################################

variable "private_path_default_access_policy" {
  type        = string
  description = "The policy to use for bindings from accounts without an explicit account policy. The default policy is set to Review all requests. Supported options are `permit`, `deny`, or `review`."
  default     = "review"
  validation {
    condition     = contains(["review", "permit", "deny"], var.private_path_default_access_policy)
    error_message = "Invalid network loadbalancer health type. Allowed values are 'review', 'permit' or 'deny'."
  }
}

variable "private_path_service_endpoints" {
  type        = list(string)
  description = "The list of name for the service endpoint where you want to connect your Private Path service. Enter a maximum number of 10 unique endpoint names for your service."
}

variable "private_path_zonal_affinity" {
  type        = bool
  description = "When enabled, the endpoint service preferentially permits connection requests from endpoints in the same zone. Without zonal affinity, requests are distributed to all instances in any zone."
  default     = false
}

variable "private_path_name" {
  type        = string
  description = "The name of the Private Path service for VPC."
  default     = "private-path"
}

variable "private_path_publish" {
  type        = bool
  description = "Set this variable to `true` to allow any account to request access to the Private Path service. If need be, you can also unpublish where access is restricted to the account that created the Private Path service by setting this variable to `false`."
  default     = false
}

variable "private_path_account_policies" {
  type = list(object({
    account       = string
    access_policy = string
  }))
  description = "The account-specific connection request policies. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-vpc-private-path/tree/main/solutions/fully-configurable/DA_inputs.md#options-with-acc-policies)."
  default     = []
}
