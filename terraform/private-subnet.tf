resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, var.private_cidr_offset)
  availability_zone       = local.az_names[0]
  map_public_ip_on_launch = false
  tags = merge(
  local.common_tags,
  {
    Name = "${var.environment}-data-pipeline-private"

  }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.environment}-data-pipeline-private"
    Environment = "${var.environment}"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}