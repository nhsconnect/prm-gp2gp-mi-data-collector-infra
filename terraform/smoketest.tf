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
}
