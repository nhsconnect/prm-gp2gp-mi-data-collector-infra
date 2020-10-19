data "aws_ami" "amazon_linux_2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
}

resource "aws_security_group" "mesh_client" {
  name   = "${var.environment}-registrations-mesh-client"
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-registrations-mesh-client"
    }
  )
}

resource "aws_security_group_rule" "mesh_client_egress" {
  type              = "egress"
  security_group_id = aws_security_group.mesh_client.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "Unrestricted egress"
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mesh_client" {
  name               = "${var.environment}-registrations-mesh-client"
  description        = "Role for mesh client instance"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "mesh_client" {
  name = "${var.environment}-registrations-mesh-client"
  role = aws_iam_role.mesh_client.name
}

resource "aws_iam_role_policy_attachment" "mesh_client_session_manager" {
  role       = aws_iam_role.mesh_client.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}

resource "aws_iam_role_policy_attachment" "mesh_client_ecr_read_only" {
  role       = aws_iam_role.mesh_client.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_instance" "mesh_client" {
  ami                         = data.aws_ami.amazon_linux_2.image_id
  instance_type               = "t3a.small"
  vpc_security_group_ids      = [aws_security_group.mesh_client.id]
  subnet_id                   = aws_subnet.public.id
  iam_instance_profile        = aws_iam_instance_profile.mesh_client.name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user-data.sh")

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-registrations-mesh-client"
    }
  )

}
