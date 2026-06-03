output "perf_results" {
  value = {
    bucket_name = oci_objectstorage_bucket.perf_results.name
    namespace   = var.oci_object_storage_namespace
    region      = var.oci_region
    s3_endpoint = "https://${var.oci_object_storage_namespace}.compat.objectstorage.${var.oci_region}.oraclecloud.com"
  }
}

output "perf_results_upload_url" {
  description = "Bucket-scoped write-only PAR URL. Share with uploaders; appended path becomes the object key."
  value       = "https://${var.oci_object_storage_namespace}.objectstorage.${var.oci_region}.oci.customer-oci.com${oci_objectstorage_preauthrequest.perf_results_upload.access_uri}"
  sensitive   = true
}

output "perf_results_upload_url_expires" {
  value = oci_objectstorage_preauthrequest.perf_results_upload.time_expires
}
