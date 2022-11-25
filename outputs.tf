output prod-ml-model-predict-endpoint {
  value = "${oci_apigateway_deployment.prod-ml-model.endpoint}/predict"
}

output test-ml-model-predict-endpoint {
  value = "${oci_apigateway_deployment.test-ml-model.endpoint}/predict"
}

output devops-code-repo-url {
    value = oci_devops_repository.mlops-code-repo.http_url
}

output ml-model-container-repo-path {
    value = "${var.ocir_url}/${data.oci_objectstorage_namespace.os_namespace.namespace}/${oci_artifacts_container_repository.mlops_model.display_name}"
}

output container-reg-auth-token-id {
    value = oci_vault_secret.container-registry-auth-token.id
}

output apex-url {
  value = oci_database_autonomous_database.mlops-adb-apex.connection_urls[*].apex_url
}


output mlops-dynamic-group {
  value = var.tenancy_admin ? null : ["resource.type='devopsrepository',resource.compartment.id='${var.compartment_ocid}'", "resource.type='devopsbuildpipeline',resource.compartment.id='${var.compartment_ocid}'", "resource.type='devopsdeploypipeline',resource.compartment.id='${var.compartment_ocid}'",   "resource.type='devopsconnection',resource.compartment.id='${var.compartment_ocid}'", "resource.type='fnfunc',resource.compartment.id='${var.compartment_ocid}'" ]
description = "Please create a dynamic group as per the above definition"
}

output mlops-dynamic-group-policy {
  value = var.tenancy_admin ? null : ["Allow dynamic-group '${var.resource_naming_prefix}-mlops-dynamic-group-policy' to manage all-resources in compartment id ${var.compartment_ocid}"]
  description = "Please create the policy in the root compartment as per the above definition"
}
