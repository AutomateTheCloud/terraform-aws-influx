resource "aws_security_group" "this" {
  name                   = "influxdb-${var.name}"
  description            = "${local.scope.name} - ${local.purpose.name} [${local.environment.name}] (${local.aws.region.name}): InfluxDB - ${var.name}"
  vpc_id                 = data.aws_vpc.this.id
  revoke_rules_on_delete = true
  tags = merge(
    local.tags,
    tomap(var.security_group_additional_tags),
    tomap({
      "Name" = "influxdb-${var.name}"
    })
  )
  provider = aws.this
}
