vpc_cidr="10.51.0.0/16"
forwarder_repo_name="registrations/mesh-inbox-s3-forwarder"
forwarder_image_tag="94066fe"
mesh_url="https://mesh.spineservices.nhs.uk"
splunk_trusted_principal_ssm_param_name="/registrations/prod/user-input/splunk-trusted-principals"
mesh_mailbox_ssm_param_name="/registrations/prod/user-input/mesh/mailbox-name"
mesh_password_ssm_param_name="/registrations/prod/user-input/mesh/mailbox-password"
mesh_shared_key_ssm_param_name="/registrations/prod/user-input/mesh/shared-key"
mesh_client_cert_ssm_param_name="/registrations/prod/user-input/mesh/mailbox-client-cert"
mesh_client_key_ssm_param_name="/registrations/prod/user-input/mesh/mailbox-client-private-key"
mesh_ca_cert_ssm_param_name="/registrations/prod/user-input/mesh/ca-certificate-chain"
