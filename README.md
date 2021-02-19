# prm-gp2gp-mi-data-collector-infra

Terraform for solution used to collect, monitor and forward GP2GP MI received via MESH.

## Setup

These instructions assume you are using:

- [aws-vault](https://github.com/99designs/aws-vault) to validate your AWS credentials.
- [dojo](https://github.com/kudulab/dojo) to provide an execution environment

## Applying terraform

Rolling out terraform against each environment is managed by the GoCD pipeline. If you'd like to test it locally, run the following commands:

1. Enter the container:

`aws-vault exec <profile-name> -- dojo`

2. Invoke terraform locally

```
  ./tasks validate dev
  ./tasks plan dev
```

## Terraform Variables

| Variable                                | Description                                                                                                            |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| vpc_cidr                                | CIDR block allocation to use for MI collector VPC                                                                      |
| forwarder_repo_name                     | ECR repo containing [mesh s3 forwarder](https://github.com/nhsconnect/prm-gp2gp-mesh-s3-forwarder) image               |
| forwarder_image_tag                     | Tag of mesh s3 forwarder image to deploy                                                                               |
| mesh_url                                | URL of MESH endpoint to connect to                                                                                     |
| splunk_trusted_principal_ssm_param_name | Name of AWS SSM parameter store entry containing trusted principals permitted to assume the splunk data collector role |
| mesh_mailbox_ssm_param_name             | Name of AWS SSM parameter store entry containing the name of the MESH inbox to consume messages from                   |
| mesh_password_ssm_param_name            | Name of AWS SSM parameter store entry containing the password of the MESH inbox to consume message from                |
| mesh_shared_key_ssm_param_name          | Name of AWS SSM parameter store entry containing the MESH shared key                                                   |
| mesh_client_cert_ssm_param_name         | Name of AWS SSM parameter store entry containing the client certificate                                                |
| mesh_client_key_ssm_param_name          | Name of AWS SSM parameter store entry containing the client certificate key                                            |
| mesh_ca_cert_ssm_param_name             | Name of AWS SSM parameter store entry containing the certificate authority chain                                       |
| alert_webhook_url_ssm_param_name        | Name of AWS SSM parameter store entry containing Microsoft Teams webhook to send monitoring alerts to                  |
