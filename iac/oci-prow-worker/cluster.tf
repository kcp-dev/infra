resource "oci_containerengine_cluster" "prow" {
  name               = "oci-prow-worker"
  kubernetes_version = var.kubernetes_version

  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.prow.id
}

resource "oci_containerengine_node_pool" "prow_worker" {
  cluster_id     = oci_containerengine_cluster.prow.id
  compartment_id = var.oci_compartment_ocid

  kubernetes_version = var.kubernetes_version
  name               = "prow-worker"
  ssh_public_key     = var.node_pool_ssh_public_key

  # this matches t3.2xlarge sizings.
  node_shape = "VM.Standard.A1.Flex"
  node_shape_config {
    memory_in_gbs = 32
    ocpus         = 8
  }


  # Using image Oracle-Linux-7.x-<date>
  # Find image OCID for your region from https://docs.oracle.com/iaas/images/
  # For now aarch64 lates k/k 1.29 image is used.
  node_source_details {
    image_id    = "ocid1.image.oc1.us-sanjose-1.aaaaaaaaceb5egr4du2d5vut6uam2kdbctilom4w5wirnz7tihe4w4y3yroq"
    source_type = "image"
  }

  node_config_details {
    size = var.node_pool_worker_size

    # create placement_configs for each availability domain.
    # There happens to be only a single one in us-sanjose-1.
    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.availability_domains.availability_domains
      content {
        availability_domain = placement_configs.value.name
        subnet_id           = oci_core_subnet.prow_worker_cluster[placement_configs.key].id
      }
    }
  }
}
