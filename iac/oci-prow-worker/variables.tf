variable "oci_tenant_ocid" {
  type = string
}

variable "oci_compartment_ocid" {
  type = string
}

variable "oci_user_ocid" {
  type = string
}

variable "oci_private_key" {
  type      = string
  sensitive = true
}

variable "oci_region" {
  type = string
}
