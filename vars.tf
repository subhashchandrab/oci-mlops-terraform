terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.3"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.13.1"
    }
    oci = {
      source = "oracle/oci"
      version = "4.101.0"
    }
  }
  required_version = ">= 1.0"
}

provider "kubernetes" {
  config_path = "$HOME/.kube/config"
}

provider "oci" {
  region          = var.region
  tenancy_ocid    = var.tenancy_ocid
}

provider "oci" {
  alias        = "home_region"
  tenancy_ocid = var.tenancy_ocid
  region       = data.oci_identity_region_subscriptions.home_region_filter.region_subscriptions[0].region_name
}

variable "compartment_ocid" {
  description = "Please provide compartment OCID."
  type        = string
}

variable "tenancy_ocid" {
  description = "Please provide tenancy OCID."
  type = string
}

variable "region" {
  description = "Please provide region for the AWX deployment."
  type        = string
}

variable "generic_vcn_cidr_blocks" {
  description = "VCN CIDR Block for Generic MLOps resources"
  default = "10.0.0.0/16"
}

variable "oke_vcn_cidr_blocks" {
  description = "VCN CIDR Blocks for OKE Cluster"
  default = "10.1.0.0/16"
}

variable "resource_naming_prefix" {
  description = "Prefix for all resource display names"
  type        = string
  default = "demo"
}

variable "oke_k8sapiendpoint_subnet_cidr_block" {
  description = "Subnet CIDR Block for OKE API Endpoint"
  default = "10.1.0.0/24"
}

variable "oke_service_lb_subnet_cidr_block" {
  description = "Subnet CIDR Block for Service Load Balancer"
  default = "10.1.1.0/24"
}

variable "oke_nodepool_cidr_block" {
  description = "Subnet CIDR Block for worker nodepool"
  default = "10.1.2.0/24"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
}

variable "node_shape" {
  description = "Instance shape of the node"
  default = "VM.Standard.E3.Flex"
}

variable "shape_ocpus" {
  description = "Number of OCPUs of each node"
  default = "2"
}

variable "shape_mems" {
  description = "Memory of each node in GB"
  default = "32"
}

variable "image_os_id" {
  description = "OS Image OCID of the node pool"
}

variable "oke_nodepool_size" {
  description = "Size of the node pool"
  default = "3"
}

variable "email_address" {
  description = "Email address for OCI DevOps Notificatio"
}

variable "ocir_url" {
  description = "URL of OCIR"
}

variable "ocir_username" {
  description = "Username for OCIR Login"
}

variable "ocir_password" {
  description = "Password for OCIR Login"
}

variable "ocir_password_base64" {
  description = "Base64-encoded Password for OCIR Login"
}

variable "ocir_email" {
  description = "Email for OCIR Login"
}

variable "create_oac" {
  description = "Important Note: Creating OAC requires admin access to IDSC to obtain access token."
  type = bool
}

variable "idsc_access_token" {
  description = "IDSC Access Token for OAC"
  default = "input token here"
}

variable "mlops_adb_admin_password" {
  description = "Password for ADB Admin"
}

variable "tenancy_admin" {
  description = "Flag to check whether the user has administrator access for the current tenancy"
  type        = bool
  default     = false
}

data "oci_core_services" "all_services" {
}

data oci_identity_availability_domain AD-1 {
  compartment_id = var.compartment_ocid
  ad_number      = "1"
}
data oci_identity_availability_domain AD-2 {
  compartment_id = var.compartment_ocid
  ad_number      = "2"
}
data oci_identity_availability_domain AD-3 {
  compartment_id = var.compartment_ocid
  ad_number      = "3"
}

data oci_objectstorage_namespace os_namespace {
  compartment_id = var.compartment_ocid
}

data "oci_identity_region_subscriptions" "home_region_filter" {
    tenancy_id = var.tenancy_ocid
    filter {
      name = "is_home_region"
      values = [true]
    }
}
