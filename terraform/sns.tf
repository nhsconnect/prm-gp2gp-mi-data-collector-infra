resource "aws_sns_topic" "mi_data_collector_canary" {
  name = "mi-data-collector-canary"
  tags = local.common_tags
}