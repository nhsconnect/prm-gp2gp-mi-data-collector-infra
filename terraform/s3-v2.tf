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