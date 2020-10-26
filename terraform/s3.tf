resource "aws_s3_bucket" "mi_data" {
  bucket = "prm-gp2gp-mi-data-${var.environment}"
  acl    = "private"

  tags = {
    Name        = "GP2GP MI data"
    CreatedBy   = var.repo_name
    Environment = var.environment
    Team        = var.team
  }
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
