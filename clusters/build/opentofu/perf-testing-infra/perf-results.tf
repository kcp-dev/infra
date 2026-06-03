resource "oci_objectstorage_bucket" "perf_results" {
  compartment_id = var.oci_compartment_ocid
  namespace      = var.oci_object_storage_namespace
  name           = var.perf_results_bucket_name

  # Anonymous GET + listing. Do not upload anything sensitive.
  access_type  = "ObjectRead"
  storage_tier = "Standard"
}

# Bucket-scoped, write-only shareable URL. Uploaders can PUT any object key
# under the bucket but cannot read, list, or touch any other bucket. The URL
# itself IS the credential — treat it like a password.
resource "oci_objectstorage_preauthrequest" "perf_results_upload" {
  namespace    = var.oci_object_storage_namespace
  bucket       = oci_objectstorage_bucket.perf_results.name
  name         = "perf-results-upload"
  access_type  = "AnyObjectWrite"
  time_expires = var.perf_results_par_expires
}
