resource "aws_iam_role" "mesh_s3_forwarder_smoke_test" {
  name               = "${var.environment}-mesh-s3-forwarder-smoke-test"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_lambda_function" "mesh_s3_forwarder_smoke_test" {
  filename      = var.smoketest_lambda_zip
  function_name = "${var.environment}-mesh-s3-forwarder-smoke-test"
  role          = aws_iam_role.mesh_s3_forwarder_smoke_test.arn
  handler       = "main.send_mesh_message"
  tags          = local.common_tags

  source_code_hash = filebase64sha256(var.smoketest_lambda_zip)

  runtime = "python3.8"

  environment {
    variables = {
      MESH_URL                        = var.mesh_url,
      MESH_MAILBOX_SSM_PARAM_NAME     = var.mesh_mailbox_ssm_param_name,
      MESH_PASSWORD_SSM_PARAM_NAME    = var.mesh_password_ssm_param_name,
      MESH_SHARED_KEY_SSM_PARAM_NAME  = var.mesh_shared_key_ssm_param_name,
      MESH_CLIENT_CERT_SSM_PARAM_NAME = var.mesh_client_cert_ssm_param_name,
      MESH_CLIENT_KEY_SSM_PARAM_NAME  = var.mesh_client_key_ssm_param_name,
      MESH_CA_CERT_SSM_PARAM_NAME     = var.mesh_ca_cert_ssm_param_name,
    }
  }
}

resource "aws_iam_role_policy_attachment" "mesh_s3_forwarder_smoke_test_ssm_access" {
  role       = aws_iam_role.mesh_s3_forwarder_smoke_test.name
  policy_arn = aws_iam_policy.ssm_access.arn
}
