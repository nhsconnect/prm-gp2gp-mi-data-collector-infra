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
