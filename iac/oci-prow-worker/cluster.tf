resource "oci_containerengine_cluster" "prow" {
  name               = "oci-prow-worker"
  kubernetes_version = var.kubernetes_version

  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.prow.id

  cluster_pod_network_options {
    cni_type = "flannel"
  }
}

resource "oci_containerengine_node_pool" "prow_worker" {
  cluster_id     = oci_containerengine_cluster.prow.id
  compartment_id = var.oci_compartment_ocid
  subnet_ids     = oci_core_subnet.prow_worker_cluster[*].id

  kubernetes_version = var.kubernetes_version
  name               = "prow-worker"
  ssh_public_key     = var.node_pool_ssh_public_key

  # this matches t3.2xlarge sizings.
  node_shape = "VM.Standard.A1.Flex"
  node_shape_config {
    memory_in_gbs = 32
    ocpus         = 8
  }

  node_config_details {
    size = var.node_pool_worker_size
    # create placement_configs for each availability domain.
    # There happens to be only a single one in us-sanjose-1.
    dynamic "placement_configs" {
      for_each = oci_core_subnet.prow_worker_cluster
      content {
        availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[index(oci_core_subnet.prow_worker_cluster, placement_configs.value)].id
        subnet_id           = placement_configs.value.id
      }
    }
  }
}
