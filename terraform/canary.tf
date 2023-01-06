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
      aws_sns_topic.mi_data_collector_alert.arn
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

resource "aws_lambda_function" "mi_data_collector_canary" {
  filename      = var.datacanary_lambda_zip
  function_name = "${var.environment}-mi-data-collector-canary"
  role          = aws_iam_role.mi_data_collector_canary.arn
  handler       = "main.monitor_object_puts"
  tags          = local.common_tags

  source_code_hash = filebase64sha256(var.datacanary_lambda_zip)

  runtime = "python3.8"

  environment {
    variables = {
      BUCKET_NAME   = aws_s3_bucket.mi_data_v2.bucket
      SNS_TOPIC_ARN = aws_sns_topic.mi_data_collector_alert.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "run_daily" {
  name        = "${var.environment}-mi-data-collector-canary"
  description = "Trigger MI Data Canary"

  schedule_expression = "cron(0 10 * * ? *)"
  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-mi-data-collector-canary"
      ApplicationRole = "AwsCloudwatchEventRule"
    }
  )
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
