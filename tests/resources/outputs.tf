##############################################################################
# Outputs
##############################################################################

output "member_ip_address_list" {
  value       = [ibm_is_floating_ip.ip.address]
  description = "IP address of the Provider VSI."
}

output "member_ip_address" {
  value       = ibm_is_floating_ip.ip.address
  description = "IP address of the Provider VSI."
}

output "existing_subnet_id" {
  value       = ibm_is_subnet.provider_subnet.id
  description = "The subnet ID."
}

output "resource_group_name" {
  value       = module.resource_group.resource_group_name
  description = "Resource group name."
}

output "region" {
  value       = var.region
  description = "Region of the resources."
}

output "sm_private_cert_crn" {
  value       = var.existing_secrets_manager_instance_crn != null ? module.secrets_manager_private_certificate[0].secret_crn : null
  description = "CRN of secrets manager private certificate"
}
