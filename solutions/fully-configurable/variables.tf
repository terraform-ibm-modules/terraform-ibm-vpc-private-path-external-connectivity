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
  description = "The name of an existing resource group to provision the resources."
  default     = null
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
  description = "The prefix to be added to all resources created by this solution. To skip using a prefix, set this value to null or an empty string. The prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It should not exceed 16 characters, must not end with a hyphen('-'), and can not contain consecutive hyphens ('--'). Example: prod-0205-pp. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

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
  description = "Optional list of tags to be added to the private path service."
  default     = []
}

variable "private_path_access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the private path service created by the module, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial for more details."
  default     = []
}

##############################################################################
# VPC Variables
##############################################################################

variable "existing_vpc_id" {
  description = "The ID of an existing VPC. If the user provides only the `existing_vpc_id`, the private path service will be provisioned in the first subnet."
  type        = string
  default     = null
  validation {
    condition     = var.existing_vpc_id == null && var.existing_subnet_id == null ? false : true
    error_message = "A value for either `existing_vpc_id` or `existing_subnet_id` should be passed."
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
}

variable "application_loadbalancer_pool_algorithm" {
  type        = string
  description = "The load-balancing algorithm for private path network load balancer pool members. Supported values are `round_robin` or `weighted_round_robin`."
  default     = "round_robin"
}

variable "application_loadbalancer_pool_member_port" {
  type        = number
  description = "The port where traffic is sent to the instance."
  default     = 80
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
  description = "The protocol used to send health check messages to instances in the pool. Supported values are `tcp` or `http`."
  default     = "http"
}

variable "application_loadbalancer_pool_protocol" {
  type        = string
  description = "The protocol used to send traffic to instances in the pool. Supported values are `tcp`, `http`, `https` or `udp`."
  default     = "http"
}

variable "application_loadbalancer_listener_port" {
  type        = number
  description = "The listener port for the private path network load balancer."
  default     = 80
}

variable "application_loadbalancer_listener_protocol" {
  type        = string
  description = "The protocol used to send traffic to instances in the pool. Supported values are `tcp`, `http`, `https` or `udp`."
  default     = "http"
}

variable "application_loadbalancer_listener_idle_timeout" {
  type        = number
  description = "The protocol used to send traffic to instances in the pool. Supported values are `tcp`, `http`, `https` or `udp`."
  default     = 50
}

variable "application_loadbalancer_listener_certificate_instance" {
  type        = string
  description = "The CRN of the certificate in your secret manager, it is applicable(mandatory) only to https protocol."
  default     = null

  validation {
    condition     = var.application_loadbalancer_listener_protocol == "https" ? var.application_loadbalancer_listener_certificate_instance != null ? true : false : true
    error_message = "A value must be set for `application_loadbalancer_listener_certificate_instance` when `application_loadbalancer_listener_protocol` is set to `https`."
  }
}


##############################################################################
# NLB Variables
##############################################################################

variable "network_loadbalancer_name" {
  type        = string
  description = "The name of the private path network load balancer."
  default     = "pp-nlb"
}

variable "network_loadbalancer_listener_port" {
  type        = number
  description = "The listener port for the private path network load balancer."
  default     = 80
}

variable "network_loadbalancer_listener_accept_proxy_protocol" {
  type        = bool
  description = "If set to true, listener forwards proxy protocol information that are supported by load balancers in the application family. Default value is false."
  default     = false
}

variable "network_loadbalancer_pool_algorithm" {
  type        = string
  description = "The load-balancing algorithm for private path network load balancer pool members. Supported values are `round_robin` or `weighted_round_robin`."
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
  description = "The protocol used to send health check messages to instances in the pool. Supported values are `tcp` or `http`."
  default     = "tcp"
}

variable "network_loadbalancer_pool_health_monitor_url" {
  type        = string
  description = "If you select HTTP as the health check protocol, this URL is used to send health check requests to the instances in the pool. By default, this is the root path `/`"
  default     = "/"
}

variable "network_loadbalancer_pool_health_monitor_port" {
  type        = number
  description = "The port on which the load balancer sends health check requests. By default, health checks are sent on the same port where traffic is sent to the instance."
  default     = 80
}

variable "network_loadbalancer_pool_member_port" {
  type        = number
  description = "The port where traffic is sent to the instance."
  default     = 80
}

##############################################################################
# Private Path Variables
##############################################################################

variable "private_path_default_access_policy" {
  type        = string
  description = "The policy to use for bindings from accounts without an explicit account policy. The default policy is set to Review all requests. Supported options are `permit`, `deny`, or `review`."
  default     = "review"
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
