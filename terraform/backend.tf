terraform {
  backend "s3" {
    bucket         = "prm-gp2gp-terraform-state"
    dynamodb_table = "prm-gp2gp-terraform-table"
    region         = "eu-west-2"
    encrypt        = true
  }
}
