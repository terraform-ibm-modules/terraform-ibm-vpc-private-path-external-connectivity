##############################################################################
# Resource group
##############################################################################

module "mock_resource_group" {
  source              = "terraform-ibm-modules/resource-group/ibm"
  version             = "1.4.7"
  resource_group_name = "${var.prefix}-mock-rg"
}

##############################################################################
# MOCK ON-PREM
##############################################################################


resource "ibm_is_vpc" "mock_vpc" {
  name           = "${var.prefix}-mock-vpc"
  resource_group = module.mock_resource_group.resource_group_id
}

resource "ibm_is_vpc_address_prefix" "mock_prefix" {
  name = "${var.prefix}-mock-prefix"
  zone = "${var.region}-1"
  vpc  = ibm_is_vpc.mock_vpc.id
  cidr = "10.100.20.0/24"
}

resource "ibm_is_subnet" "mock_subnet" {
  depends_on = [
    ibm_is_vpc_address_prefix.mock_prefix
  ]
  name            = "${var.prefix}-mock-vpc"
  vpc             = ibm_is_vpc.mock_vpc.id
  zone            = "${var.region}-1"
  ipv4_cidr_block = "10.100.20.0/24"
  resource_group  = module.mock_resource_group.resource_group_id
  tags            = var.resource_tags
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
}

resource "ibm_is_ssh_key" "public_key" {
  name           = "${var.prefix}-key"
  public_key     = trimspace(tls_private_key.ssh_key.public_key_openssh)
  resource_group = module.mock_resource_group.resource_group_id
}

data "ibm_is_image" "image" {
  name = "ibm-ubuntu-22-04-3-minimal-amd64-1"
}

resource "ibm_is_instance" "vsi" {
  name           = "${var.prefix}-vsi-0"
  image          = data.ibm_is_image.image.id
  resource_group = module.mock_resource_group.resource_group_id
  profile        = "bx2-2x8"

  primary_network_attachment {
    name = "${var.prefix}-vsi-0"
    virtual_network_interface {
      subnet = ibm_is_subnet.mock_subnet.id
    }
  }

  vpc       = ibm_is_vpc.mock_vpc.id
  zone      = "${var.region}-1"
  keys      = [ibm_is_ssh_key.public_key.id]
  user_data = file("./userdata.sh")
}

resource "ibm_is_floating_ip" "ip" {
  name           = "${var.prefix}-fip"
  target         = ibm_is_instance.vsi.primary_network_attachment[0].virtual_network_interface[0].id
  resource_group = module.mock_resource_group.resource_group_id
}

################################################################################
# Resource Group
################################################################################
module "resource_group" {
  source              = "terraform-ibm-modules/resource-group/ibm"
  version             = "1.4.7"
  resource_group_name = "${var.prefix}-rg"
}

##############################################################################
# Provider VPC
##############################################################################


resource "ibm_is_vpc" "provider_vpc" {
  name           = "${var.prefix}-provider-vpc"
  resource_group = module.resource_group.resource_group_id
}

resource "ibm_is_vpc_address_prefix" "prefix" {
  name = "${var.prefix}-prefix"
  zone = "${var.region}-1"
  vpc  = ibm_is_vpc.provider_vpc.id
  cidr = "10.100.10.0/24"
}

resource "ibm_is_subnet" "provider_subnet" {
  depends_on = [
    ibm_is_vpc_address_prefix.prefix
  ]
  name            = "${var.prefix}-provider-vpc"
  vpc             = ibm_is_vpc.provider_vpc.id
  resource_group  = module.resource_group.resource_group_id
  zone            = "${var.region}-1"
  ipv4_cidr_block = "10.100.10.0/24"
  tags            = var.resource_tags
}

#################################################################################
# Secrets Manager resources
#################################################################################

locals {
  sm_region            = var.existing_secrets_manager_instance_crn != null ? module.existing_sm_crn_parser[0].region : null
  secrets_manager_guid = var.existing_secrets_manager_instance_crn != null ? module.existing_sm_crn_parser[0].service_instance : null
}

module "existing_sm_crn_parser" {
  count   = var.existing_secrets_manager_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.3.7"
  crn     = var.existing_secrets_manager_instance_crn
}

# Create a secret group to place the certificate if provisioning a new certificate
module "secrets_manager_group" {
  count                    = var.existing_secrets_manager_instance_crn != null ? 1 : 0
  source                   = "terraform-ibm-modules/secrets-manager-secret-group/ibm"
  version                  = "1.3.34"
  region                   = local.sm_region
  secrets_manager_guid     = local.secrets_manager_guid
  secret_group_name        = "${var.prefix}-cert-secret-group"
  secret_group_description = "secret group used for private certificates"
  providers = {
    ibm = ibm.ibm-sm
  }
}

# Create private certificate to use for VPN server
module "secrets_manager_private_certificate" {
  count                  = var.existing_secrets_manager_instance_crn != null ? 1 : 0
  source                 = "terraform-ibm-modules/secrets-manager-private-cert/ibm"
  version                = "1.10.9"
  cert_name              = "${var.prefix}-cts-vpn-private-cert"
  cert_description       = "an example private cert"
  cert_template          = var.certificate_template_name
  cert_secrets_group_id  = module.secrets_manager_group[0].secret_group_id
  cert_common_name       = "${var.prefix}-example.com"
  secrets_manager_guid   = local.secrets_manager_guid
  secrets_manager_region = local.sm_region
  providers = {
    ibm = ibm.ibm-sm
  }
}
