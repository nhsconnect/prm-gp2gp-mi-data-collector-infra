resource "aws_cloudwatch_log_metric_filter" "forward_message_event" {
  name           = "${var.environment}-mesh-s3-forward-message-event"
  pattern        = "{ $.message = \"FORWARD_MESH_MESSAGE\" }"
  log_group_name = aws_cloudwatch_log_group.mesh_s3_forwarder.name

  metric_transformation {
    name          = "ForwardMessageEventCount"
    namespace     = "MeshS3Forwarder/${var.environment}"
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
        "width" : 6,
        "height" : 3,
        "properties" : {
          "metrics" : [
            [
              "${aws_cloudwatch_log_metric_filter.forward_message_event.metric_transformation[0].namespace}",
              "${aws_cloudwatch_log_metric_filter.forward_message_event.name}"
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