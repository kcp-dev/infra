provider "oci" {
  tenancy_ocid = ""
  user_ocid    = ""
  private_key  = ""
  region       = ""
}

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.oci_tenant_ocid
}

