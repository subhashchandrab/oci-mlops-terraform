
resource oci_core_vcn test-oke-vcn {
  cidr_blocks = [
    var.oke_vcn_cidr_blocks,
  ]
  compartment_id = var.compartment_ocid
  display_name = "${var.resource_naming_prefix}-test-oke-vcn"
  dns_label    = "testokecluster"
}

resource oci_core_internet_gateway test-oke-igw {
  depends_on     = [oci_core_vcn.test-oke-vcn]
  compartment_id = var.compartment_ocid
  display_name = "${var.resource_naming_prefix}-test-oke-igw"
  vcn_id = oci_core_vcn.test-oke-vcn.id
}

resource oci_core_service_gateway test-oke-sgw {
  depends_on     = [oci_core_vcn.test-oke-vcn]
  compartment_id = var.compartment_ocid
  display_name = "${var.resource_naming_prefix}-test-oke-sgw"
  services {
    service_id = data.oci_core_services.all_services.services.0.id
  }
  vcn_id = oci_core_vcn.test-oke-vcn.id
}


resource oci_core_nat_gateway test-oke-ngw {
  depends_on     = [oci_core_vcn.test-oke-vcn]
  compartment_id = var.compartment_ocid
  display_name = "${var.resource_naming_prefix}-test-oke-ngw"
  vcn_id       = oci_core_vcn.test-oke-vcn.id
}

resource oci_core_default_route_table test-oke-public-routetable {
  depends_on     = [oci_core_vcn.test-oke-vcn, oci_core_internet_gateway.test-oke-igw]
  compartment_id = var.compartment_ocid
  display_name = "Default Route Table for test-oke"
  manage_default_resource_id = oci_core_vcn.test-oke-vcn.default_route_table_id
  route_rules {
    description       = "traffic to/from internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.test-oke-igw.id
  }
}

resource oci_core_route_table test-oke-private-routetable {
  depends_on     = [oci_core_vcn.test-oke-vcn, oci_core_nat_gateway.test-oke-ngw, oci_core_service_gateway.test-oke-sgw]
  compartment_id = var.compartment_ocid
  display_name = "Private Route Table for test-oke"
  route_rules {
    description       = "traffic to the internet"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.test-oke-ngw.id
  }
  route_rules {
    description       = "traffic to OCI services"
    destination       = data.oci_core_services.all_services.services.0.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.test-oke-sgw.id
  }
  vcn_id = oci_core_vcn.test-oke-vcn.id
}

## ----- Test OKE Subnets and Security Lists ----- ##

resource oci_core_subnet test-oke-k8sapiendpoint-subnet {
  depends_on     = [oci_core_vcn.test-oke-vcn, oci_core_default_route_table.test-oke-public-routetable, oci_core_security_list.test-oke-k8sapiendpoint-sl]
  cidr_block = var.oke_k8sapiendpoint_subnet_cidr_block
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.test-oke-vcn.id
  display_name = "${var.resource_naming_prefix}-test-oke-k8sapiendpoint-subnet"
  route_table_id =  oci_core_default_route_table.test-oke-public-routetable.id
  security_list_ids = [oci_core_security_list.test-oke-k8sapiendpoint-sl.id]
}

resource oci_core_subnet test-oke-service_lb-subnet {
  cidr_block = var.oke_service_lb_subnet_cidr_block
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.test-oke-vcn.id
  display_name = "${var.resource_naming_prefix}-test-oke-service_lb-subnet"
  route_table_id = oci_core_default_route_table.test-oke-public-routetable.id
  security_list_ids = [oci_core_security_list.test-oke-service_lb-sl.id]
}

resource oci_core_subnet test-oke-nodepool-subnet {
  cidr_block = var.oke_nodepool_cidr_block
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.test-oke-vcn.id
  display_name = "${var.resource_naming_prefix}-test-oke-nodepool-subnet"
  route_table_id = oci_core_route_table.test-oke-private-routetable.id
  security_list_ids = [oci_core_security_list.test-oke-nodepool-sl.id]
}

resource oci_core_security_list test-oke-k8sapiendpoint-sl {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.test-oke-vcn.id
  display_name = "${var.resource_naming_prefix}-test-oke-k8sapiendpoint-sl"
  
  egress_security_rules {
		description = "Allow Kubernetes Control Plane to communicate with OKE"
		destination = data.oci_core_services.all_services.services.0.cidr_block
		destination_type = "SERVICE_CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "All traffic to worker nodes"
		destination = var.oke_nodepool_cidr_block
		destination_type = "CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "Path discovery"
		destination = var.oke_nodepool_cidr_block
		destination_type = "CIDR_BLOCK"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		stateless = "false"
	}
	ingress_security_rules {
		description = "External access to Kubernetes API endpoint"
		protocol = "6"
		source = "0.0.0.0/0"
		stateless = "false"
	}
	ingress_security_rules {
		description = "Kubernetes worker to Kubernetes API endpoint communication"
		protocol = "6"
		source = var.oke_nodepool_cidr_block
		stateless = "false"
	}
	ingress_security_rules {
		description = "Kubernetes worker to control plane communication"
		protocol = "6"
		source = var.oke_nodepool_cidr_block
		stateless = "false"
	}
	ingress_security_rules {
		description = "Path discovery"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		source = var.oke_nodepool_cidr_block
		stateless = "false"
	}
}

resource oci_core_security_list test-oke-service_lb-sl {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.test-oke-vcn.id
  display_name = "${var.resource_naming_prefix}-test-oke-service_lb-sl"
}

resource oci_core_security_list test-oke-nodepool-sl {
  compartment_id = var.compartment_ocid
  vcn_id = oci_core_vcn.test-oke-vcn.id
  display_name = "${var.resource_naming_prefix}-test-oke-nodepool-sl"

  egress_security_rules {
		description = "Allow pods on one worker node to communicate with pods on other worker nodes"
		destination = var.oke_nodepool_cidr_block
		destination_type = "CIDR_BLOCK"
		protocol = "all"
		stateless = "false"
	}
	egress_security_rules {
		description = "Access to Kubernetes API Endpoint"
		destination = oci_core_subnet.test-oke-k8sapiendpoint-subnet.cidr_block
		destination_type = "CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
    tcp_options {
      max = "6443"
      min = "6443"
      source_port_range {
		  max = "65535"
		  min = "1"
      }
    }
	}
	egress_security_rules {
		description = "Kubernetes worker to control plane communication"
		destination = oci_core_subnet.test-oke-k8sapiendpoint-subnet.cidr_block
		destination_type = "CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
    tcp_options {
      max = "12250"
      min = "12250"
      source_port_range {
        max = "65535"
        min = "1"
      }
    }
	}
	egress_security_rules {
		description = "Path discovery"
		destination = oci_core_subnet.test-oke-k8sapiendpoint-subnet.cidr_block
		destination_type = "CIDR_BLOCK"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		stateless = "false"
	}
	egress_security_rules {
		description = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
		destination = data.oci_core_services.all_services.services.0.cidr_block
		destination_type = "SERVICE_CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
    tcp_options {
      max = "443"
      min = "443"
      source_port_range {
        max = "65535"
        min = "1"
      }
    }
	}
	egress_security_rules {
		description = "ICMP Access from Kubernetes Control Plane"
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		stateless = "false"
	}
	egress_security_rules {
		description = "Worker Nodes access to Internet"
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		protocol = "all"
		stateless = "false"
	}
	ingress_security_rules {
		description = "Allow pods on one worker node to communicate with pods on other worker nodes"
		protocol = "all"
		source = var.oke_nodepool_cidr_block
		stateless = "false"
	}
	ingress_security_rules {
		description = "Path discovery"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		source = oci_core_subnet.test-oke-k8sapiendpoint-subnet.cidr_block
		stateless = "false"
	}
	ingress_security_rules {
		description = "TCP access from Kubernetes Control Plane"
		protocol = "6"
		source = oci_core_subnet.test-oke-k8sapiendpoint-subnet.cidr_block
		stateless = "false"
	}
	ingress_security_rules {
		description = "Inbound SSH traffic to worker nodes"
		protocol = "6"
		source = "0.0.0.0/0"
		stateless = "false"
    tcp_options {
      max = "22"
      min = "22"
      source_port_range {
        max = "65535"
        min = "1"
      }
    }
	}
}
##----- Test OKE Cluster -----##

resource oci_containerengine_cluster test-oke-cluster {
  compartment_id = var.compartment_ocid
  endpoint_config {
    is_public_ip_enabled = "true"
    nsg_ids = [
    ]
    subnet_id = oci_core_subnet.test-oke-k8sapiendpoint-subnet.id
  }
  image_policy_config {
    is_policy_enabled = "false"
  }
  kubernetes_version = var.kubernetes_version
  name               = "${var.resource_naming_prefix}-test-oke-cluster"
  options {
    add_ons {
      is_kubernetes_dashboard_enabled = "false"
      is_tiller_enabled               = "false"
    }
    admission_controller_options {
      is_pod_security_policy_enabled = "false"
    }
#    kubernetes_network_config {
#      pods_cidr     = "10.244.0.0/16"
#      services_cidr = "10.96.0.0/16"
#    }
    service_lb_subnet_ids = [
      oci_core_subnet.test-oke-service_lb-subnet.id,
    ]
  }
  vcn_id = oci_core_vcn.test-oke-vcn.id
}

## ----- Test OKE Node Pool ----- ##

resource oci_containerengine_node_pool test-oke-pool1 {
  cluster_id     = oci_containerengine_cluster.test-oke-cluster.id
  compartment_id = var.compartment_ocid
  initial_node_labels {
    key   = "name"
    value = "test-oke-cluster"
  }
  kubernetes_version = var.kubernetes_version
  name               = "test-oke-pool1"
  node_config_details {
    nsg_ids = [
    ]
    placement_configs {
      availability_domain = data.oci_identity_availability_domain.AD-1.name
      subnet_id           = oci_core_subnet.test-oke-nodepool-subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domain.AD-2.name
      subnet_id           = oci_core_subnet.test-oke-nodepool-subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domain.AD-3.name
      subnet_id           = oci_core_subnet.test-oke-nodepool-subnet.id
    }
    size = var.oke_nodepool_size
  }
  node_metadata = {
  }
  node_shape = var.node_shape
  node_eviction_node_pool_settings {
    eviction_grace_duration = "PT0M"
    is_force_delete_after_grace_duration = "true"
  }  
  node_shape_config {
    memory_in_gbs = var.shape_mems
    ocpus         = var.shape_ocpus
  }
  node_source_details {
    image_id    = var.image_os_id
    source_type = "IMAGE"
  }
  
}

