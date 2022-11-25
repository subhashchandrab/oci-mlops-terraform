## Container Registry ##

resource oci_artifacts_container_repository trigger_build_function {
    compartment_id = var.compartment_ocid
    display_name = "${var.resource_naming_prefix}-trigger-build"
    is_public = "false"
}

resource oci_artifacts_container_repository test_mlmodel_function {
    compartment_id = var.compartment_ocid
    display_name = "${var.resource_naming_prefix}-test-ml-model"
    is_public = "false"
}

resource oci_artifacts_container_repository mlops_model {
    compartment_id = var.compartment_ocid
    display_name = "${var.resource_naming_prefix}-mlops-model"
    is_public = "false"
}
