provider "oci" {
  tenancy_ocid        = var.oci_tenant_ocid
  region              = var.oci_region
  auth                = var.oci_auth_type
  config_file_profile = var.oci_config_file_profile
}
