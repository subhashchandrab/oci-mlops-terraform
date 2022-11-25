## ------- Virtual Cloud Network -------- ##
resource oci_core_vcn mlops-vcn {
  cidr_blocks = [
    var.generic_vcn_cidr_blocks,
  ]
  compartment_id = var.compartment_ocid
  display_name = "${var.resource_naming_prefix}-mlops-vcn"
  dns_label    = "mlopsvcn"
}


## ------- Internet Gateway -------- ##
resource oci_core_internet_gateway mlops-igw {
  depends_on     = [oci_core_vcn.mlops-vcn]
  compartment_id = var.compartment_ocid
  display_name = "${var.resource_naming_prefix}-mlops-igw"
  vcn_id = oci_core_vcn.mlops-vcn.id
}

## ------- Default Public Route Table ------- ##

resource oci_core_default_route_table mlops-default-routetable {
  depends_on     = [oci_core_vcn.mlops-vcn, oci_core_internet_gateway.mlops-igw]
  compartment_id = var.compartment_ocid
  display_name = "Default Route Table for mlops-vcn"
  manage_default_resource_id = oci_core_vcn.mlops-vcn.default_route_table_id
  route_rules {
    description       = "traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.mlops-igw.id
  }
}


## ----- MLOps Public Subnet ----- ##
resource oci_core_subnet mlops-public-subnet {
  depends_on     = [oci_core_vcn.mlops-vcn, oci_core_default_route_table.mlops-default-routetable, oci_core_security_list.mlops-public-sl]
  cidr_block = var.generic_vcn_cidr_blocks
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.mlops-vcn.id
  display_name = "${var.resource_naming_prefix}-mlops-public-subnet"
  route_table_id =  oci_core_default_route_table.mlops-default-routetable.id
  security_list_ids = [oci_core_security_list.mlops-public-sl.id]
}

resource oci_core_security_list mlops-public-sl {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.mlops-vcn.id
  display_name = "${var.resource_naming_prefix}-mlops-public-sl"

  egress_security_rules {
	  description = "Allow all traffic"
	  destination = "0.0.0.0/0"
	  protocol = "all"
	  stateless = "false"
  }

  ingress_security_rules {
	  description = "Allow all traffic"
	  source = "0.0.0.0/0"
	  protocol = "all"
	  stateless = "false"
  }
}