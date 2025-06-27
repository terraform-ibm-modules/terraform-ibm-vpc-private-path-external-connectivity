##############################################################################
# Outputs
##############################################################################
output "resource_group_name" {
  value       = module.resource_group.resource_group_name
  description = "The name of the Resource Group the instances are provisioned in."
}

output "resource_group_id" {
  value       = module.resource_group.resource_group_id
  description = "The ID of the Resource Group the instances are provisioned in."
}

## Application Load balancer
output "alb_crn" {
  description = "The CRN for this application load balancer."
  value       = ibm_is_lb.alb.crn
}

output "alb_id" {
  description = "The unique identifier of the application load balancer."
  value       = ibm_is_lb.alb.id
}

output "alb_pool_id" {
  description = "The unique identifier of the application load balancer pool."
  value       = ibm_is_lb_pool.alb_backend_pool.id
}

output "alb_pool_member_id" {
  description = "The unique identifier of the application load balancer pool member."
  value = { for key, value in ibm_is_lb_pool_member.alb_pool_members :
  key => value.id }
}

output "alb_listener_id" {
  description = "The unique identifier of the application load balancer listener."
  value       = ibm_is_lb_listener.alb_frontend_listener.id
}

## Private Path
output "nlb_crn" {
  description = "The CRN for this load balancer."
  value       = module.private_path.lb_crn
}

output "nlb_id" {
  description = "The unique identifier of the load balancer."
  value       = module.private_path.lb_id
}

output "nlb_pool_id" {
  description = "The unique identifier of the load balancer pool."
  value       = module.private_path.pool_id
}

output "nlb_pool_member_id" {
  description = "The unique identifier of the load balancer pool member."
  value       = module.private_path.pool_member_id
}

output "nlb_listener_id" {
  description = "The unique identifier of the load balancer listener."
  value       = module.private_path.listener_id
}

output "private_path_crn" {
  description = "The CRN for this private path service gateway."
  value       = module.private_path.private_path_crn
}

output "private_path_id" {
  description = "The unique identifier of the PrivatePathServiceGateway."
  value       = module.private_path.private_path_id
}

output "private_path_vpc" {
  description = "The VPC this private path service gateway resides in."
  value       = module.private_path.private_path_vpc
}

output "account_policy_id" {
  description = "The unique identifier of the PrivatePathServiceGatewayAccountPolicy."
  value       = module.private_path.account_policy_id
}
