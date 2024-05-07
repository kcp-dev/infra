provider "oci" {
  tenancy_ocid = var.oci_tenant_ocid
  region       = var.oci_region
}

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.oci_tenant_ocid
}

