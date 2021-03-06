resource "aws_s3_bucket" "mi_data" {
  bucket = "prm-gp2gp-mi-data-${var.environment}"
  acl    = "private"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-GP2GP-MI-data"
    }
  )
}

resource "aws_s3_bucket_public_access_block" "mi_data" {
  bucket = aws_s3_bucket.mi_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "data_bucket_access" {
  statement {
    sid = "ListObjectsInBucket"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.mi_data.bucket}",
    ]
  }

  statement {
    sid = "AllObjectActions"

    actions = [
      "s3:*Object"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.mi_data.bucket}/*",
    ]
  }
}

resource "aws_iam_policy" "data_bucket_access" {
  name   = "${aws_s3_bucket.mi_data.bucket}-bucket-access"
  policy = data.aws_iam_policy_document.data_bucket_access.json
}

resource "aws_s3_bucket_metric" "data_bucket_metrics" {
  bucket = aws_s3_bucket.mi_data.bucket
  name   = "EntireBucket"
}