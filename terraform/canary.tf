resource "aws_sns_topic" "mi_data_collector_canary" {
  name = "${var.environment}-mi-data-collector-canary"
  tags = local.common_tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "mi_data_collector_canary" {
  statement {
    sid = "ReadMetrics"

    actions = [
      "cloudwatch:GetMetricData"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "SNSPublish"

    actions = [
      "SNS:Publish"
    ]

    resources = [
      aws_sns_topic.mi_data_collector_canary.arn
    ]
  }
}

resource "aws_iam_policy" "mi_data_collector_canary" {
  name   = "${var.environment}-mi-data-collector-canary"
  policy = data.aws_iam_policy_document.mi_data_collector_canary.json
}

resource "aws_iam_role" "mi_data_collector_canary" {
  name               = "${var.environment}-mi-data-collector-canary"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "mi_data_collector_canary" {
  role       = aws_iam_role.mi_data_collector_canary.name
  policy_arn = aws_iam_policy.mi_data_collector_canary.arn
}

data "archive_file" "mi_data_collector_canary" {
  type        = "zip"
  source_file = "${path.module}/datacanary.py"
  output_path = "${path.module}/datacanary.zip"
}

resource "aws_lambda_function" "mi_data_collector_canary" {
  filename      = data.archive_file.mi_data_collector_canary.output_path
  function_name = "${var.environment}-mi-data-collector-canary"
  role          = aws_iam_role.mi_data_collector_canary.arn
  handler       = "datacanary.monitor_object_puts"
  tags          = local.common_tags

  source_code_hash = filesha256(data.archive_file.mi_data_collector_canary.source_file)

  runtime = "python3.8"

  environment {
    variables = {
      bucket_name   = aws_s3_bucket.mi_data_v2.bucket
      sns_topic_arn = aws_sns_topic.mi_data_collector_canary.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "run_daily" {
  name        = "${var.environment}-mi-data-collector-canary"
  description = "Trigger MI Data Canary"

  schedule_expression = "cron(0 10 * * ? *)"
  tags                = local.common_tags
}

resource "aws_cloudwatch_event_target" "mi_data_collector_canary" {
  target_id = "${var.environment}-mi-data-collector-canary"
  rule      = aws_cloudwatch_event_rule.run_daily.name
  arn       = aws_lambda_function.mi_data_collector_canary.arn
}


resource "aws_lambda_permission" "invoke_canary" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mi_data_collector_canary.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.run_daily.arn
}