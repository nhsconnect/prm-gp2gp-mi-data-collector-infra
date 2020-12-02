vpc_cidr="10.50.0.0/16"
forwarder_repo_name="registrations/mesh-inbox-s3-forwarder"
forwarder_image_tag="a8063ee"
mesh_url="https://mesh.spineservices.nhs.uk"
splunk_trusted_principal_ssm_param_name="/registrations/dev/user-input/splunk-trusted-principals"
mesh_mailbox_ssm_param_name="/registrations/dev/user-input/test-mesh-mailbox-username"
mesh_password_ssm_param_name="/registrations/dev/user-input/test-mesh-mailbox-password"
mesh_shared_key_ssm_param_name="/registrations/dev/user-input/mesh-shared-key"
mesh_client_cert_ssm_param_name="/registrations/dev/user-input/test-mailbox-client-cert"
mesh_client_key_ssm_param_name="/registrations/dev/user-input/test-mailbox-client-private-key"
mesh_ca_cert_ssm_param_name="/registrations/dev/user-input/ca-certificate-chain"