resource "aws_ecs_cluster" "mi_data_collector" {
  name = "${var.environment}-registrations-mi-collector"
  tags = local.common_tags
}
