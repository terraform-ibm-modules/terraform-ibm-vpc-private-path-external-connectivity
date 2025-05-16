#################################################################################
# Using the IBM supported resource group and COS modules from                   #
# https://github.com/terraform-ibm-modules/terraform-ibm-cos and                #
# https://github.com/terraform-ibm-modules/terraform-ibm-resource-group         #
# to provision a COS instance and 2 regional buckets in different regions.      #
#################################################################################

# optionally create the resource group, or lookup existing one
module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.use_existing_resource_group == false ? (var.prefix != null ? "${var.prefix}-${var.resource_group_name}" : var.resource_group_name) : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
}

# create global COS instance
module "cos_instance" {
  source            = "terraform-ibm-modules/cos/ibm"
  version           = "8.19.2"
  resource_group_id = module.resource_group.resource_group_id
  cos_instance_name = var.prefix != null ? "${var.prefix}-${var.cos_instance_name}" : var.cos_instance_name
  create_cos_bucket = false
}

# create a source and target COS bucket
locals {
  cos_source_bucket_name = var.prefix != null ? "${var.prefix}-${var.cos_source_bucket_name}" : var.cos_source_bucket_name
  cos_target_bucket_name = var.prefix != null ? "${var.prefix}-${var.cos_target_bucket_name}" : var.cos_target_bucket_name
}

module "cos_buckets" {
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "8.19.2"
  bucket_configs = [
    {
      bucket_name            = local.cos_source_bucket_name
      kms_encryption_enabled = false
      region_location        = var.cos_source_bucket_region
      resource_instance_id   = module.cos_instance.cos_instance_id
      add_bucket_name_suffix = var.add_bucket_name_suffix
      object_versioning      = { enable = true }
    },
    {
      bucket_name            = local.cos_target_bucket_name
      kms_encryption_enabled = false
      region_location        = var.cos_target_bucket_region
      resource_instance_id   = module.cos_instance.cos_instance_id
      add_bucket_name_suffix = var.add_bucket_name_suffix
      object_versioning      = { enable = true }
    }
  ]
}

#################################################################################
# Using the IBM terraform provider 'ibm_cos_bucket_replication_rule' resource   #
# to create a replication rule to copy everything from the source bucket to the #
# target bucket.                                                                #
#################################################################################

# create replication rule
resource "ibm_cos_bucket_replication_rule" "cos_replication_rule" {
  depends_on = [
    ibm_iam_authorization_policy.policy
  ]
  bucket_crn      = module.cos_buckets.buckets[local.cos_source_bucket_name].bucket_crn
  bucket_location = var.cos_source_bucket_region
  replication_rule {
    rule_id                         = "replicate-everything"
    enable                          = true
    priority                        = 50
    deletemarker_replication_status = false
    destination_bucket_crn          = module.cos_buckets.buckets[local.cos_target_bucket_name].bucket_crn
  }
}

#################################################################################
# Using the IBM terraform provider 'ibm_iam_authorization_policy' resource      #
# to create the IAM authorization policy required to configure replication.     #
#################################################################################

# use data source to get the account ID required to create the authorization policy
data "ibm_iam_account_settings" "iam_account_settings" {
}

resource "ibm_iam_authorization_policy" "policy" {
  roles = [
    "Writer",
  ]
  subject_attributes {
    name  = "accountId"
    value = data.ibm_iam_account_settings.iam_account_settings.account_id
  }
  subject_attributes {
    name  = "serviceName"
    value = "cloud-object-storage"
  }
  subject_attributes {
    name  = "serviceInstance"
    value = module.cos_instance.cos_instance_guid
  }
  subject_attributes {
    name  = "resource"
    value = module.cos_buckets.buckets[local.cos_source_bucket_name].bucket_name
  }
  subject_attributes {
    name  = "resourceType"
    value = "bucket"
  }
  resource_attributes {
    name  = "accountId"
    value = data.ibm_iam_account_settings.iam_account_settings.account_id
  }
  resource_attributes {
    name  = "serviceName"
    value = "cloud-object-storage"
  }
  resource_attributes {
    name  = "serviceInstance"
    value = module.cos_instance.cos_instance_guid
  }
  resource_attributes {
    name  = "resource"
    value = module.cos_buckets.buckets[local.cos_target_bucket_name].bucket_name
  }
  resource_attributes {
    name  = "resourceType"
    value = "bucket"
  }
}
