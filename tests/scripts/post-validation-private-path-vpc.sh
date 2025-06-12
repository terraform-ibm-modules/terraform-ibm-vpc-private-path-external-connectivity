#! /bin/bash

########################################################################################################################
## This script is used by the catalog pipeline to destroy the VPC, which was provisioned as a                         ##
## prerequisite for the VPC Private path extension solutions that is published to the catalog                         ##
########################################################################################################################

set -e

TERRAFORM_SOURCE_DIR="tests/resources"
TF_VARS_FILE="terraform.tfvars"

(
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Destroying prerequisite VPC .."
  terraform destroy -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1
  rm -f "${TF_VARS_FILE}"

  echo "Post-validation complete successfully"
)
