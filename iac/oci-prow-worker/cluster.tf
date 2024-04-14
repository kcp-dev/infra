resource "oci_containerengine_cluster" "prow" {
  name               = "oci-prow-worker"
  type               = "TODO"
  kubernetes_version = "v1.29.1"

  compartment_id = var.oci_compartment_ocid
  vcn_id         = "TODO"

  cluster_pod_network_options {
    cni_type = "flannel"
  }
  endpoint_config {
    is_public_ip_enabled = true
    nsg_ids              = "TODO"
    subnet_id            = "TODO"
  }
}
