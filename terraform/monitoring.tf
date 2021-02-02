locals {
  forward_message_metric_name        = "ForwardMessageEventCount"
  inbox_message_count_metric_name    = "InboxMessageCount"
  mesh_s3_forwarder_metric_namespace = "MeshS3Forwarder/${var.environment}"
  error_count_table_query            = "SOURCE '${aws_cloudwatch_log_group.mesh_s3_forwarder.name}'| fields @timestamp, error | filter ispresent(error) | stats count(*) as totalCount by error, bin (1h) as timeframe"
  error_count_graph_query            = "SOURCE '${aws_cloudwatch_log_group.mesh_s3_forwarder.name}'| fields @timestamp, error | filter ispresent(error) | stats count(*) as totalCount by bin (1h)"
}

resource "aws_cloudwatch_log_metric_filter" "forward_message_event" {
  name           = "${var.environment}-mesh-s3-forward-message-event"
  pattern        = "{ $.event = \"FORWARD_MESH_MESSAGE\" }"
  log_group_name = aws_cloudwatch_log_group.mesh_s3_forwarder.name

  metric_transformation {
    name          = local.forward_message_metric_name
    namespace     = local.mesh_s3_forwarder_metric_namespace
    value         = 1
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "inbox_message_count" {
  name           = "${var.environment}-mesh-inbox-message-count"
  pattern        = "{ $.event = \"COUNT_MESSAGES\" }"
  log_group_name = aws_cloudwatch_log_group.mesh_s3_forwarder.name

  metric_transformation {
    name      = local.inbox_message_count_metric_name
    namespace = local.mesh_s3_forwarder_metric_namespace
    value     = "$.inboxMessageCount"
  }
}

resource "aws_cloudwatch_dashboard" "mesh_s3_forwarder" {
  dashboard_name = "${var.environment}-mesh-s3-forwarder"
  dashboard_body = jsonencode({
    "start" : "-P3D"
    "widgets" : [
      {
        "type" : "metric",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              local.mesh_s3_forwarder_metric_namespace,
              local.forward_message_metric_name
            ]
          ],
          "period" : 900,
          "stat" : "Sum",
          "region" : var.region,
          "title" : "Number of messages forwarded"

        }
      },
      {
        "type" : "metric",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              local.mesh_s3_forwarder_metric_namespace,
              local.inbox_message_count_metric_name
            ]
          ],
          "period" : 300,
          "stat" : "Maximum",
          "region" : var.region,
          "title" : "MESH Inbox Message Count"
        } }, {
        "type" : "log",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : var.region,
          "title" : "Total count of errors grouped by error type and hour",
          "query" : local.error_count_table_query,
          "view" : "table"
        }
        }, {
        "type" : "log",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : var.region,
          "title" : "Total count of all errors",
          "query" : local.error_count_graph_query,
          "view" : "timeSeries"
        }
      },
    ]
  })
}