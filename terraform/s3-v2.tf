resource "aws_s3_bucket" "mi_data_v2" {
  bucket = "prm-gp2gp-mi-data-${var.environment}-v2"
  acl    = "private"

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

locals {
  notifications_queue_name = "${aws_s3_bucket.mi_data_v2.bucket}-notifications"
  notifications_topic_name = "${aws_s3_bucket.mi_data_v2.bucket}-notifications"
}

data "aws_iam_policy_document" "data_bucket_v2_notification_sns" {
  statement {
    actions = [
      "sns:Publish"
    ]

    resources = [
      "arn:aws:sns:*:*:${local.notifications_topic_name}",
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
  name = local.notifications_topic_name
  policy = data.aws_iam_policy_document.data_bucket_v2_notification_sns.json
}

resource "aws_sqs_queue" "data_bucket_v2_notifications" {
  name   = local.notifications_queue_name
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
