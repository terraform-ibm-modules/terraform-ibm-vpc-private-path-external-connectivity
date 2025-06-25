terraform {
  required_version = ">= 1.9.0"
  required_providers {
    # Lock deployable architecture into an exact provider version - renovate automation will keep it updated
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.79.2"
    }
  }
}
