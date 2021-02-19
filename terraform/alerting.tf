resource "aws_cloudwatch_metric_alarm" "mesh_inbox_message_count" {
  alarm_name          = "${var.environment}-mesh-inbox-message-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "6"
  metric_name         = aws_cloudwatch_log_metric_filter.inbox_message_count.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.inbox_message_count.metric_transformation[0].namespace
  period              = "3600"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "There are unprocessed messages in the MESH inbox for more than 6 hours."
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.mi_data_collector_alert.arn]
  treat_missing_data  = "breaching"
  tags                = local.common_tags
}
resource "aws_cloudwatch_metric_alarm" "dead_letter_queue_message_count" {
  alarm_name          = "${var.environment}-dead-letter-queue-message-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "600"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "There are messages in the MI data notifications SQS dead letter queue."
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.mi_data_collector_alert.arn]
  tags                = local.common_tags
  dimensions = {
    QueueName = aws_sqs_queue.data_bucket_v2_notifications_deadletter.name
  }
}
resource "aws_cloudwatch_metric_alarm" "mesh_s3_forwarder_ecs_task_count" {
  alarm_name          = "${var.environment}-mesh-s3-forwarder-ecs-task-count"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "12"
  metric_name         = "TaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = "300"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "No tasks running continuously within 1 hour."
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.mi_data_collector_alert.arn]
  treat_missing_data  = "breaching"
  tags                = local.common_tags
  dimensions = {
    ClusterName = aws_ecs_cluster.mi_data_collector.name
  }
}

resource "aws_lambda_function" "mi_data_collector_alert" {
  filename      = var.alert_lambda_zip
  function_name = "${var.environment}-mi-data-collector-alert"
  role          = aws_iam_role.mi_data_collector_alert.arn
  handler       = "main.lambda_handler"
  tags          = local.common_tags

  source_code_hash = filebase64sha256(var.alert_lambda_zip)

  runtime = "python3.8"

  environment {
    variables = {
      ALERT_WEBHOOK_URL_PARAM_NAME = var.alert_webhook_url_ssm_param_name
      AWS_ALARM_REGION             = var.region
    }
  }
}
resource "aws_iam_role" "mi_data_collector_alert" {
  name               = "${var.environment}-mi-data-collector-alert"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "webhook_ssm_access" {
  statement {
    sid = "GetSSMParameter"

    actions = [
      "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter${var.alert_webhook_url_ssm_param_name}"
    ]
  }
}

resource "aws_iam_policy" "webhook_ssm_access" {
  name   = "${var.environment}-webhook-ssm-access"
  policy = data.aws_iam_policy_document.webhook_ssm_access.json
}

resource "aws_iam_role_policy_attachment" "mi_data_collector_alert" {
  role       = aws_iam_role.mi_data_collector_alert.name
  policy_arn = aws_iam_policy.webhook_ssm_access.arn
}

resource "aws_lambda_permission" "allow_invocation_from_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mi_data_collector_alert.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.mi_data_collector_alert.arn
}

resource "aws_sns_topic_subscription" "mi_data_collector_alert" {
  topic_arn = aws_sns_topic.mi_data_collector_alert.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.mi_data_collector_alert.arn
}

resource "aws_sns_topic" "mi_data_collector_alert" {
  name = "${var.environment}-mi-data-collector-alert"
  tags = local.common_tags
}
