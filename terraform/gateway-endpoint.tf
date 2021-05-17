resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = merge(
  local.common_tags,
  {
    Name = "${var.environment}-data-pipeline-private"

  }
  )
}
resource "aws_vpc_endpoint_route_table_association" "s3" {
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

data "aws_region" "current" {}