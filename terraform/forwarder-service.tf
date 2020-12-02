resource "aws_ecs_cluster" "mi_data_collector" {
  name = "${var.environment}-registrations-mi-collector"
  tags = local.common_tags
}

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

data "aws_iam_policy_document" "ecs_assume" {
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
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution.arn
}

resource "aws_iam_policy" "ecs_execution" {
  name   = "${var.environment}-ecs-execution"
  policy = data.aws_iam_policy_document.ecs_execution.json
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
      "${aws_cloudwatch_log_group.mesh_s3_forwarder.arn}:*"
    ]
  }
}

resource "aws_iam_role" "forwarder" {
  name               = "${var.environment}-registrations-mesh-s3-forwarder"
  description        = "Role for mesh forwarder ECS task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "s3_bucket_access" {
  role       = aws_iam_role.forwarder.name
  policy_arn = aws_iam_policy.data_bucket_v2_access.arn
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.forwarder.name
  policy_arn = aws_iam_policy.ssm_access.arn
}

resource "aws_iam_policy" "ssm_access" {
  name   = "${var.environment}-ssm-access"
  policy = data.aws_iam_policy_document.ssm_access.json
}

data "aws_iam_policy_document" "ssm_access" {
  statement {
    sid = "GetSSMParameter"

    actions = [
        "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/registrations/${var.environment}/user-input/mesh/*"
    ]
  }
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "forwarder" {
  family = "${var.environment}-mesh-s3-forwarder"
  container_definitions = jsonencode([
    {
      name        = "mesh-s3-forwarder"
      image       = "${data.aws_ecr_repository.mesh_s3_forwarder.repository_url}:${var.forwarder_image_tag}"
      environment = [
        {"name": "MESH_URL", "value": var.mesh_url}, 
        {"name": "MESH_MAILBOX_SSM_PARAM_NAME", "value": var.mesh_mailbox_ssm_param_name},
        {"name": "MESH_PASSWORD_SSM_PARAM_NAME", "value": var.mesh_password_ssm_param_name},
        {"name": "MESH_SHARED_KEY_SSM_PARAM_NAME", "value": var.mesh_shared_key_ssm_param_name},
        {"name": "MESH_CLIENT_CERT_SSM_PARAM_NAME", "value": var.mesh_client_cert_ssm_param_name},
        {"name": "MESH_CLIENT_KEY_SSM_PARAM_NAME", "value": var.mesh_client_key_ssm_param_name},
        {"name": "MESH_CA_CERT_SSM_PARAM_NAME", "value": var.mesh_ca_cert_ssm_param_name},
        {"name": "S3_BUCKET_NAME", "value": aws_s3_bucket.mi_data_v2.bucket}
      ]
      essential   = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.mesh_s3_forwarder.name
          awslogs-region        = var.region
          awslogs-stream-prefix = var.forwarder_image_tag
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
  task_role_arn = aws_iam_role.forwarder.arn
}

resource "aws_ecs_service" "forwarder" {
  name            = "${var.environment}-mesh-s3-forwarder"
  cluster         = aws_ecs_cluster.mi_data_collector.id
  task_definition = aws_ecs_task_definition.forwarder.arn
  launch_type = "FARGATE"
  desired_count   = 1
 
  network_configuration {
      subnets = [aws_subnet.public.id]
      assign_public_ip = true
      security_groups = [aws_security_group.forwarder.id]
    }
}

resource "aws_security_group" "forwarder" {
  name   = "${var.environment}-mesh-s3-forwarder"
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-mesh-s3-forwarder"
    }
  )
}

resource "aws_security_group_rule" "forwarder" {
  type              = "egress"
  security_group_id = aws_security_group.forwarder.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "Unrestricted egress"
}