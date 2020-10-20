resource "aws_ecs_cluster" "mi_data_collector" {
  name = "${var.environment}-registrations-mi-collector"
  tags = local.common_tags
}

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = [
      "ec2:DescribeTags",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_agent" {
  name   = "${aws_ecs_cluster.mi_data_collector.name}-agent"
  policy = data.aws_iam_policy_document.ecs_agent.json
}
