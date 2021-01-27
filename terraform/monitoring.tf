locals {
  forward_message_metric_name        = "ForwardMessageEventCount"
  mesh_s3_forwarder_metric_namespace = "MeshS3Forwarder/${var.environment}"
}

resource "aws_cloudwatch_log_metric_filter" "forward_message_event" {
  name           = "${var.environment}-mesh-s3-forward-message-event"
  pattern        = "{ $.message = \"FORWARD_MESH_MESSAGE\" }"
  log_group_name = aws_cloudwatch_log_group.mesh_s3_forwarder.name

  metric_transformation {
    name          = local.forward_message_metric_name
    namespace     = local.mesh_s3_forwarder_metric_namespace
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_dashboard" "mesh_s3_forwarder" {
  dashboard_name = "${var.environment}-mesh-s3-forwarder"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              local.mesh_s3_forwarder_metric_namespace,
              local.forward_message_metric_name
            ]
          ],
          "period" : 300,
          "region" : var.region,
          "title" : "${aws_cloudwatch_log_metric_filter.forward_message_event.name}"
        }
      }
    ]
  })
}