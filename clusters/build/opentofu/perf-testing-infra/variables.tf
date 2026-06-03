variable "oci_tenant_ocid" {
  type = string
}

variable "oci_compartment_ocid" {
  type = string
}

variable "oci_region" {
  type = string
}

variable "oci_config_file_profile" {
  type    = string
  default = "DEFAULT"
}

variable "oci_auth_type" {
  type    = string
  default = "SecurityToken"
}

variable "perf_results_bucket_name" {
  type    = string
  default = "kcp-perf-results"
}

variable "oci_object_storage_namespace" {
  type        = string
  description = "OCI Object Storage namespace for the tenancy. Find it in the OCI Console or as the <ID> in https://<ID>.compat.objectstorage.<region>.oraclecloud.com."
}

variable "perf_results_par_expires" {
  type        = string
  description = "RFC3339 timestamp at which the upload PAR expires. Bump and re-apply (or taint the PAR) to rotate the shared URL."
  default     = "2027-06-03T00:00:00Z"
}
