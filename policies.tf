## These resources require administrator privileges on tenancy ##

##---- Dynamic Groups ----##
resource "oci_identity_dynamic_group" "mlops_dynamic_group" {
	count = var.tenancy_admin == true ? 1 : 0
	provider = oci.home_region
    compartment_id = var.tenancy_ocid
    description = "Dynamic group for the DevOps project resources and functions to be used in MLOps environment"
    matching_rule = "Any {All {resource.type='devopsrepository',resource.compartment.id='${var.compartment_ocid}' }, All {resource.type='devopsbuildpipeline',resource.compartment.id='${var.compartment_ocid}' }, All {resource.type='devopsdeploypipeline',resource.compartment.id='${var.compartment_ocid}' }, All {resource.type='devopsconnection',resource.compartment.id='${var.compartment_ocid}' }, All {resource.type='fnfunc',resource.compartment.id='${var.compartment_ocid}' }}"
    name = "${var.resource_naming_prefix}-mlops-dynamic-group"

}

##---- IAM Policies ----##
resource "oci_identity_policy" "mlops_dynamic_group_policy" {
	count = var.tenancy_admin == true ? 1 : 0
    provider = oci.home_region
	depends_on = [oci_identity_dynamic_group.mlops_dynamic_group]
    compartment_id = var.tenancy_ocid
    description = "IAM Policy for providing the resource access for the dyamic group in MLOps environment"
    name = "${var.resource_naming_prefix}-mlops-dynamic-group-policy"
    statements = ["Allow dynamic-group '${var.resource_naming_prefix}-mlops-dynamic-group-policy' to manage all-resources in compartment id ${var.compartment_ocid}"]
}