##############################################################################
# Outputs
##############################################################################

output "access_group_id" {
  description = "Access group ID."
  value       = ibm_iam_access_group_policy.policy.access_group_id
}

output "website_endpoint" {
  description = "Website endpoint."
  value       = ibm_cos_bucket_website_configuration.website.website_endpoint
}
