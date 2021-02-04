locals {
  forward_message_metric_name        = "ForwardMessageEventCount"
  inbox_message_count_metric_name    = "InboxMessageCount"
  mesh_s3_forwarder_metric_namespace = "MeshS3Forwarder/${var.environment}"
  error_count_table_query            = "SOURCE '${aws_cloudwatch_log_group.mesh_s3_forwarder.name}' | fields @timestamp, error | filter ispresent(error) | stats count(*) as totalCount by error, bin (1h) as timeframe"
  error_count_graph_query            = "SOURCE '${aws_cloudwatch_log_group.mesh_s3_forwarder.name}' | fields @timestamp, error | filter ispresent(error) | stats count(*) as totalCount by bin (1h)"
  messages_per_sender_table_query    = "SOURCE '${aws_cloudwatch_log_group.mesh_s3_forwarder.name}' | filter event = \"FORWARD_MESH_MESSAGE\" | stats count(*) as totalCount by sender"
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

resource "aws_cloudwatch_dashboard" "mi_collector" {
  dashboard_name = "${var.environment}-mi-collector"
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
          "title" : "Count of messages forwarded"

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
          "title" : "Count of messages in MESH Inbox"
        }
      },
      {
        "type" : "log",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : var.region,
          "title" : "Count of errors grouped by error type and hour",
          "query" : local.error_count_table_query,
          "view" : "table"
        }
      },
      {
        "type" : "log",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : var.region,
          "title" : "Count of all errors",
          "query" : local.error_count_graph_query,
          "view" : "timeSeries"
        }
      },
      {
        "type" : "log",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : var.region,
          "title" : "Count of messages per sender",
          "query" : local.messages_per_sender_table_query,
          "view" : "table"
        }
      },
      {
        "type" : "metric",
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              "AWS/SQS",
              "ApproximateNumberOfMessagesVisible",
              "QueueName",
              aws_sqs_queue.data_bucket_v2_notifications_deadletter.name
            ]
          ],
          "stat" : "Maximum",
          "region" : var.region,
          "title" : "Count of messages in dead letter queue",
          "view" : "timeSeries"
        }
      },
      {
        "type" : "metric",
        "width" : 6,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              "ECS/ContainerInsights",
              "TaskCount",
              "ClusterName",
              aws_ecs_cluster.mi_data_collector.name,
              { "stat" : "Average" }
            ]
          ],
          "region" : var.region,
          "title" : "Count of running ECS tasks",
          "view" : "timeSeries"
        }
      },
      {
        "type" : "metric",
        "width" : 6,
        "height" : 6,
        "properties" : {
          "metrics" : [
            [
              "ECS/ContainerInsights",
              "ServiceCount",
              "ClusterName",
              aws_ecs_cluster.mi_data_collector.name,
              { "stat" : "Average" }
            ]
          ],
          "region" : var.region,
          "title" : "Count of services in the ECS cluster",
          "view" : "timeSeries"
        }
      },
    ]
  })
}