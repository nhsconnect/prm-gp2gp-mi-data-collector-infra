resource "aws_cloudwatch_log_metric_filter" "forward_message_event" {
  name           = "${var.environment}-mesh-s3-forward-message-event"
  pattern        = "{ $.message = \"FORWARD_MESH_MESSAGE\" }"
  log_group_name = aws_cloudwatch_log_group.mesh_s3_forwarder.name

  metric_transformation {
    name      = "ForwardMessageEventCount"
    namespace = "MeshS3Forwarder/${var.environment}"
    value     = 1
    default_value = 0
  }
}