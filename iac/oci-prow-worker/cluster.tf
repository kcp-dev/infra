resource "oci_containerengine_cluster" "prow" {
  name               = "oci-prow-worker"
  kubernetes_version = "v1.29.1"

  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.prow.id

  cluster_pod_network_options {
    cni_type = "flannel"
  }
}

resource "oci_containerengine_node_pool" "prow_worker" {
  cluster_id         = oci_containerengine_cluster.prow.id
  compartment_id     = var.oci_compartment_ocid
  kubernetes_version = "v1.29.1"
  name               = "prow-worker"
  node_shape         = "VM.Standard2.1"
  subnet_ids         = oci_core_subnet.prow_worker_cluster[*].id

  ssh_public_key      = var.node_pool_ssh_public_key

  node_config_details {
    size = 3
    dynamic "placement_configs" {
      for_each = oci_core_subnet.prow_worker_cluster
      content {
        availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[index(oci_core_subnet.prow_worker_cluster, placement_configs.value)].id
        subnet_id = placement_configs.value.id
      }
    }
  }
}
