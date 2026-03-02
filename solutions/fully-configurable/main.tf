#######################################################################################################################
# Resource Group
#######################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.8"
  existing_resource_group_name = var.existing_resource_group_name
}

########################################################################################################################
# Secrets Manager resources
########################################################################################################################
locals {
  secrets_manager_cert_crn        = var.application_loadbalancer_listener_certificate_crn != null ? var.application_loadbalancer_listener_certificate_crn : module.secrets_manager_private_certificate[0].secret_crn
  secrets_manager_secret_group_id = var.application_loadbalancer_listener_certificate_crn != null ? null : var.existing_secrets_manager_secret_group_id != null ? var.existing_secrets_manager_secret_group_id : module.secrets_manager_secret_group[0].secret_group_id
}
module "existing_sm_crn_parser" {
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.4.2"
  crn     = var.existing_secrets_manager_instance_crn
}

module "application_loadbalancer_listener_certificate_crn_parser" {
  count   = var.application_loadbalancer_listener_certificate_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.4.2"
  crn     = var.application_loadbalancer_listener_certificate_crn
}

# Create a secret group to place the certificate if provisioning a new certificate
module "secrets_manager_secret_group" {
  count                    = var.application_loadbalancer_listener_certificate_crn == null && var.existing_secrets_manager_secret_group_id == null ? 1 : 0
  source                   = "terraform-ibm-modules/secrets-manager-secret-group/ibm"
  version                  = "1.4.7"
  region                   = module.existing_sm_crn_parser.region
  secrets_manager_guid     = module.existing_sm_crn_parser.service_instance
  secret_group_name        = (var.prefix != null && var.prefix != "") ? "${var.prefix}-cert-secret-group" : "cert-secret-group"
  secret_group_description = "secret group used for private certificates"
  providers = {
    ibm = ibm.ibm-sm
  }
}

# Create private certificate to use for VPN server
module "secrets_manager_private_certificate" {
  count                  = var.application_loadbalancer_listener_certificate_crn == null ? 1 : 0
  source                 = "terraform-ibm-modules/secrets-manager-private-cert/ibm"
  version                = "1.11.2"
  cert_name              = (var.prefix != null && var.prefix != "") ? "${var.prefix}-cts-vpn-private-cert" : "cts-vpn-private-cert"
  cert_description       = "private certificate for client to site VPN connection"
  cert_template          = var.private_cert_engine_config_template_name
  cert_secrets_group_id  = local.secrets_manager_secret_group_id
  cert_common_name       = var.private_cert_engine_config_root_ca_common_name
  secrets_manager_guid   = module.existing_sm_crn_parser.service_instance
  secrets_manager_region = module.existing_sm_crn_parser.region
  providers = {
    ibm = ibm.ibm-sm
  }
}

########################################################################################################################
# Application Load balancer resources
########################################################################################################################

module "existing_vpc_crn_parser" {
  count   = var.existing_vpc_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.4.2"
  crn     = var.existing_vpc_crn
}

locals {
  prefix                    = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  network_loadbalancer_name = "${local.prefix}${var.network_loadbalancer_name}"
  private_path_name         = "${local.prefix}${var.private_path_name}"
  subnet_id                 = var.existing_subnet_id != null ? var.existing_subnet_id : data.ibm_is_vpc.vpc[0].subnets[0].id
  existing_vpc_id           = var.existing_vpc_crn != null ? module.existing_vpc_crn_parser[0].resource : null
}

data "ibm_is_vpc" "vpc" {
  count      = var.existing_vpc_crn != null && var.existing_subnet_id == null ? 1 : 0
  identifier = local.existing_vpc_id
}

resource "ibm_is_lb" "alb" {
  name           = "${local.prefix}alb"
  resource_group = module.resource_group.resource_group_id
  subnets        = [local.subnet_id]
  type           = var.application_loadbalancer_type
}

resource "ibm_is_lb_pool" "alb_backend_pool" {
  name           = "${local.prefix}alb-pool"
  lb             = ibm_is_lb.alb.id
  algorithm      = var.application_loadbalancer_pool_algorithm
  protocol       = var.application_loadbalancer_pool_protocol
  health_delay   = var.application_loadbalancer_pool_health_delay
  health_retries = var.application_loadbalancer_pool_health_retries
  health_timeout = var.application_loadbalancer_pool_health_timeout
  health_type    = var.application_loadbalancer_pool_health_type
}

resource "ibm_is_lb_pool_member" "alb_pool_members" {
  count          = length(var.application_loadbalancer_pool_member_ip_address)
  port           = var.application_loadbalancer_pool_member_port
  lb             = ibm_is_lb.alb.id
  pool           = element(split("/", ibm_is_lb_pool.alb_backend_pool.pool_id), 1)
  target_address = var.application_loadbalancer_pool_member_ip_address[count.index]
}

resource "ibm_is_lb_listener" "alb_frontend_listener" {
  lb                      = ibm_is_lb.alb.id
  port                    = var.application_loadbalancer_listener_port
  protocol                = var.application_loadbalancer_listener_protocol
  idle_connection_timeout = var.application_loadbalancer_listener_idle_timeout
  certificate_instance    = local.secrets_manager_cert_crn
  default_pool            = ibm_is_lb_pool.alb_backend_pool.pool_id
}

########################################################################################################################
# Private path resources
########################################################################################################################

module "private_path" {
  source            = "terraform-ibm-modules/vpc-private-path/ibm"
  version           = "1.6.10"
  resource_group_id = module.resource_group.resource_group_id
  subnet_id         = local.subnet_id
  tags              = var.private_path_tags
  access_tags       = var.private_path_access_tags
  nlb_name          = local.network_loadbalancer_name
  nlb_backend_pools = [
    {
      pool_name                                = "on-prem"
      pool_member_application_load_balancer_id = ibm_is_lb.alb.id
      pool_algorithm                           = var.network_loadbalancer_pool_algorithm
      pool_health_delay                        = var.network_loadbalancer_pool_health_delay
      pool_health_retries                      = var.network_loadbalancer_pool_health_retries
      pool_health_timeout                      = var.network_loadbalancer_pool_health_timeout
      pool_health_type                         = var.network_loadbalancer_pool_health_type
      pool_health_monitor_url                  = var.network_loadbalancer_pool_health_monitor_url
      pool_health_monitor_port                 = var.network_loadbalancer_pool_health_monitor_port
      pool_member_port                         = var.network_loadbalancer_pool_member_port
      listener_port                            = var.network_loadbalancer_listener_port
      listener_accept_proxy_protocol           = var.network_loadbalancer_listener_accept_proxy_protocol
  }]
  private_path_name                  = local.private_path_name
  private_path_default_access_policy = var.private_path_default_access_policy
  private_path_service_endpoints     = var.private_path_service_endpoints
  private_path_zonal_affinity        = var.private_path_zonal_affinity
  private_path_publish               = var.private_path_publish
  private_path_account_policies      = var.private_path_account_policies
}
