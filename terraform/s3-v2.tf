resource "aws_s3_bucket" "mi_data_v2" {
  bucket = "prm-gp2gp-mi-data-${var.environment}-v2"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-GP2GP-MI-data-v2"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "mi_data_v2" {
  bucket = aws_s3_bucket.mi_data_v2.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "data_bucket_v2_access" {
  statement {
    sid = "ListObjectsInBucket"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.mi_data_v2.bucket}",
    ]
  }

  statement {
    sid = "AllObjectActions"

    actions = [
      "s3:*Object"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.mi_data_v2.bucket}/*",
    ]
  }
}

resource "aws_iam_policy" "data_bucket_v2_access" {
  name   = "${aws_s3_bucket.mi_data_v2.bucket}-bucket-access"
  policy = data.aws_iam_policy_document.data_bucket_v2_access.json
}

resource "aws_s3_bucket_metric" "data_bucket_v2_metrics" {
  bucket = aws_s3_bucket.mi_data_v2.bucket
  name   = "EntireBucket"

}

data "aws_iam_policy_document" "data_bucket_v2_notification_sqs" {
  statement {
    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.data_bucket_v2_notifications.arn,
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.data_bucket_v2_notifications.arn]
    }
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }

}

data "aws_iam_policy_document" "data_bucket_v2_notification_sns" {
  statement {
    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.data_bucket_v2_notifications.arn,
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.mi_data_v2.arn]
    }

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }

}

resource "aws_sns_topic" "data_bucket_v2_notifications" {
  name = "${aws_s3_bucket.mi_data_v2.bucket}-notifications"
  tags = local.common_tags
}

resource "aws_sns_topic_policy" "data_bucket_v2_notifications" {
  arn    = aws_sns_topic.data_bucket_v2_notifications.arn
  policy = data.aws_iam_policy_document.data_bucket_v2_notification_sns.json
}

resource "aws_sqs_queue" "data_bucket_v2_notifications" {
  name                       = "${aws_s3_bucket.mi_data_v2.bucket}-notifications"
  message_retention_seconds = 1209600
  visibility_timeout_seconds = 300
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.data_bucket_v2_notifications_deadletter.arn
    maxReceiveCount     = 4
  })
  tags = local.common_tags
}

resource "aws_sqs_queue" "data_bucket_v2_notifications_deadletter" {
  name = "${aws_s3_bucket.mi_data_v2.bucket}-notifications-deadletter"
  message_retention_seconds = 1209600
  tags = local.common_tags
}

resource "aws_sqs_queue_policy" "data_bucket_v2_notifications" {
  queue_url = aws_sqs_queue.data_bucket_v2_notifications.id
  policy    = data.aws_iam_policy_document.data_bucket_v2_notification_sqs.json
}

resource "aws_sns_topic_subscription" "forward_sns_to_sqs" {
  topic_arn = aws_sns_topic.data_bucket_v2_notifications.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.data_bucket_v2_notifications.arn
}

resource "aws_s3_bucket_notification" "data_bucket_v2_notifications" {
  bucket = aws_s3_bucket.mi_data_v2.id

  topic {
    topic_arn = aws_sns_topic.data_bucket_v2_notifications.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

data "aws_ssm_parameter" "splunk_trusted_principals" {
  name = var.splunk_trusted_principal_ssm_param_name
}

locals {
  splunk_trusted_principals = split(",", data.aws_ssm_parameter.splunk_trusted_principals.value)
}

data "aws_iam_policy_document" "splunk_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = local.splunk_trusted_principals
    }
  }
}

resource "aws_iam_role" "splunk" {
  name               = "${var.environment}-registrations-splunk-mi-collector"
  description        = "Role for Splunk MI data collector"
  assume_role_policy = data.aws_iam_policy_document.splunk_assume_role.json
}

data "aws_iam_policy_document" "splunk_s3_collector" {

  statement {
    sid = "ListSQSQueus"
    actions = [
      "sqs:ListQueues"
    ]
    resources = ["*"]
  }
  statement {
    sid = "ReadMIS3Objects"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.mi_data_v2.bucket}/*",
    ]

  }
  statement {
    sid = "ConsumeSQS"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.data_bucket_v2_notifications.arn
    ]
  }
}

resource "aws_iam_policy" "splunk_s3_collector" {
  name   = "${aws_s3_bucket.mi_data_v2.bucket}-splunk-collector"
  policy = data.aws_iam_policy_document.splunk_s3_collector.json
}

resource "aws_iam_role_policy_attachment" "splunk_s3_collector" {
  role       = aws_iam_role.splunk.name
  policy_arn = aws_iam_policy.splunk_s3_collector.arn
}
