data "aws_ecr_repository" "mesh_s3_forwarder" {
  name = var.forwarder_repo_name
}

resource "aws_cloudwatch_log_group" "mesh_s3_forwarder" {
  name = "/ecs/${var.environment}-mesh-s3-forwarder"
  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-mesh-s3-forwarder"
    }
  )
}

data "aws_iam_policy_document" "ecs_execution_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.environment}-registrations-mesh-forwarder-task"
  description        = "ECS task role for launching mesh s3 forwarder"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume.json
}

data "aws_iam_policy_document" "ecs_execution" {
  statement {
    sid = "GetEcrAuthToken"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    sid = "DownloadEcrImage"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = [
      data.aws_ecr_repository.mesh_s3_forwarder.arn
    ]
  }

  statement {
    sid = "CloudwatchLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.mesh_s3_forwarder.arn
    ]
  }
}


resource "aws_ecs_task_definition" "forwarder" {
  family = "${var.environment}-mesh-s3-forwarder"
  container_definitions = jsonencode([
    {
      name        = "mesh-s3-forwarder"
      image       = "${data.aws_ecr_repository.mesh_s3_forwarder.repository_url}:${var.forwarder_image_tag}"
      environment = []
      essential   = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.mesh_s3_forwarder.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "${var.forwarder_repo_name}:${var.forwarder_image_tag}"
        }
      }
    }
  ])
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-mesh-s3-forwarder"
    }
  )
  execution_role_arn = aws_iam_role.ecs_execution.arn
}
