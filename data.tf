data "aws_vpc" "this" {
  id       = var.vpc_id
  provider = aws.this
}

data "aws_subnets" "this" {
  count = try(var.subnets_tag, null) != null ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  filter {
    name   = "tag:Network"
    values = [try(var.subnets_tag, "")]
  }
  provider = aws.this
}
