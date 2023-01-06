resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-registrations-mesh-vpc"
      ApplicationRole = "AwsVpc"
    }
  )
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.environment}-registrations-mesh-gateway"
      ApplicationRole = "AwsInternetGateway"
    }
  )

}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_names = data.aws_availability_zones.available.names
}
