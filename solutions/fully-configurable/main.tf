#######################################################################################################################
# Resource Group
#######################################################################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.0"
  existing_resource_group_name = var.existing_resource_group_name
}

locals {
  prefix                    = var.prefix != null ? trimspace(var.prefix) != "" ? "${var.prefix}-" : "" : ""
  network_loadbalancer_name = "${local.prefix}${var.network_loadbalancer_name}"
  private_path_name         = "${local.prefix}${var.private_path_name}"
  subnet_id                 = var.existing_subnet_id != null ? var.existing_subnet_id : data.ibm_is_vpc.vpc[0].subnets[0].id
}

data "ibm_is_vpc" "vpc" {
  count      = var.existing_vpc_id != null && var.existing_subnet_id == null ? 1 : 0
  identifier = var.existing_vpc_id
}

resource "ibm_is_lb" "alb" {
  name           = "${local.prefix}-alb"
  resource_group = module.resource_group.resource_group_id
  subnets        = [local.subnet_id]
  type           = var.application_loadbalancer_type
}

resource "ibm_is_lb_pool" "alb_backend_pool" {
  name           = "${local.prefix}-alb-pool"
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
  certificate_instance    = var.application_loadbalancer_listener_certificate_instance
  default_pool            = ibm_is_lb_pool.alb_backend_pool.pool_id
}

module "private_path" {
  source            = "terraform-ibm-modules/vpc-private-path/ibm"
  version           = "1.2.16"
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
