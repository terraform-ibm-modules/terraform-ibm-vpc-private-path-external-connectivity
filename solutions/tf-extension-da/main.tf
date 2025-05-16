#################################################################################
# Using the IBM terraform provider 'ibm_cos_bucket_website_configuration'       #
# resource to add the configuration required to host a static website on a      #
# given Object Storage bucket                                                   #
#################################################################################

# use a data lookup to get the ID of the "Public Access" IAM access group
data "ibm_iam_access_group" "public_access_group" {
  access_group_name = "Public Access"
}

# create an IAM access policy to granting public access to this bucket
# (required required to access the hosted website)
resource "ibm_iam_access_group_policy" "policy" {
  access_group_id = data.ibm_iam_access_group.public_access_group.groups[0].id
  roles           = ["Object Reader"]

  resources {
    service              = "cloud-object-storage"
    resource_type        = "bucket"
    resource_instance_id = var.cos_instance_guid
    resource             = var.cos_bucket_name
  }
}

# configure the COS bucket for static web hosting
resource "ibm_cos_bucket_website_configuration" "website" {
  bucket_crn      = var.cos_bucket_crn
  bucket_location = var.cos_bucket_location
  website_configuration {
    error_document {
      key = var.error_document
    }
    index_document {
      suffix = var.index_document
    }
  }
}
