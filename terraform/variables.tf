variable "environment" {
  type        = string
  description = "Uniquely identifies each deployment, i.e. dev, prod."
}

variable "team" {
  type        = string
  default     = "Registrations"
  description = "Team owning this resource"
}

variable "repo_name" {
  type        = string
  default     = "prm-gp2gp-mi-data-collector-infra"
  description = "Name of this git repository"
}

variable "region" {
  type        = string
  description = "AWS region."
  default     = "eu-west-2"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block to assign VPC"
}

variable "forwarder_repo_name" {
  type        = string
  description = "Docker repository of Mesh to S3 forwarder"
}

variable "forwarder_image_tag" {
  type        = string
  description = "Docker image tag of Mesh to S3 forwarder"
}

variable "mesh_url" {
  type        = string
  description = "URL of MESH service"
}

variable "splunk_trusted_principal_ssm_param_name" {
  type        = string
  description = "Name of SSM parameter containing Splunk trusted principal"
}

variable "mesh_mailbox_ssm_param_name" {
  type        = string
  description = "Name of SSM parameter containing MESH mailbox name"
}

variable "mesh_password_ssm_param_name" {
  type        = string
  description = "Name of SSM parameter containing MESH mailbox password"
}

variable "mesh_shared_key_ssm_param_name" {
  type        = string
  description = "Name of SSM parameter containing MESH shared key"
}

variable "mesh_client_cert_ssm_param_name" {
  type        = string
  description = "Name of SSM parameter containing MESH client certificate"
}

variable "mesh_client_key_ssm_param_name" {
  type        = string
  description = "Name of SSM parameter containing MESH client key"
}

variable "mesh_ca_cert_ssm_param_name" {
  type        = string
  description = "Name of SSM parameter containing MESH CA certificate"
}