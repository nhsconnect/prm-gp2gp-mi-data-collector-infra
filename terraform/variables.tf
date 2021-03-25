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

variable "alert_webhook_url_ssm_param_name" {
  type        = string
  description = "Name of SSM parameter containing MI Data Collector Alert webhook URL"
}

variable "datacanary_lambda_zip" {
  type        = string
  description = "path to zipfile containing lambda code for data canary"
  default     = "lambda/build/datacanary.zip"
}

variable "smoketest_lambda_zip" {
  type        = string
  description = "path to zipfile containing lambda code for forwarder smoke test"
  default     = "lambda/build/smoketest.zip"
}

variable "alert_lambda_zip" {
  type        = string
  description = "path to zipfile containing lambda code for MI Data collector alerts"
  default     = "lambda/build/alert.zip"
}

variable "log_retention_in_days" {
  type        = number
  description = "days to keep the cloudwatch logs"
  default     = 180
}
