resource "oci_core_vcn" "prow" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.oci_compartment_ocid
  display_name   = "Prow Network"
}

resource "oci_core_internet_gateway" "prow" {
  compartment_id = var.oci_compartment_ocid
  display_name   = "Prow Internet Gateway"
  vcn_id         = oci_core_vcn.prow.id
}

resource "oci_core_route_table" "prow_worker" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.prow.id
  display_name   = "Prow Worker Route Table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.prow.id
  }
}

resource "oci_core_security_list" "node_api_access" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.prow.id
  display_name   = "Prow Worker Kubernetes API Access"

  # Allow access from anywhere to Kubernetes API port.
  ingress_security_rules {
    protocol = "6" # TCP

    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # Allow node pool CIDR to access port for proxymux.
  ingress_security_rules {
    protocol = "6" # TCP

    source      = "10.0.64.0/18"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 12250
      max = 12250
    }
  }
}

resource "oci_core_security_list" "control_plane_node_access" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.prow.id
  display_name   = "Control Plane Worker Access"

  # Allow VPC CIDR to access kubelet API.
  ingress_security_rules {
    protocol = "6" # TCP

    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"

    tcp_options {
      min = 10250
      max = 10250
    }
  }
}


resource "oci_core_subnet" "prow_worker_nodes" {
  availability_domain = null
  cidr_block          = "10.0.64.0/18"
  compartment_id      = var.oci_compartment_ocid
  vcn_id              = oci_core_vcn.prow.id

  security_list_ids = [oci_core_vcn.prow.default_security_list_id, oci_core_security_list.control_plane_node_access.id]
  route_table_id    = oci_core_route_table.prow_worker.id
  display_name      = "Prow Nodes/Pods Subnet"
}

resource "oci_core_subnet" "prow_worker_cluster" {
  availability_domain = null
  cidr_block          = "10.0.10.0/24"
  compartment_id      = var.oci_compartment_ocid
  vcn_id              = oci_core_vcn.prow.id

  security_list_ids = [oci_core_vcn.prow.default_security_list_id, oci_core_security_list.node_api_access.id]
  route_table_id    = oci_core_route_table.prow_worker.id
  dhcp_options_id   = oci_core_vcn.prow.default_dhcp_options_id
  display_name      = "Prow Cluster Subnet"
}
