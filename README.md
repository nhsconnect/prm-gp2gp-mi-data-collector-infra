# prm-gp2gp-mi-data-collector-infra

Terraform for deploying underlying resources on which to deploy the GP2GP MI
Data Collector onto AWS.

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
  ./tasks validate
  ./tasks plan dev
```
