resource "aws_security_group_rule" "ingress" {
  for_each                 = { for rule in var.security_group_rules : join(";", [rule.source]) => rule }
  security_group_id        = aws_security_group.this.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "8086"
  to_port                  = "8086"
  cidr_blocks              = (can(cidrnetmask(each.value["source"])) ? [each.value["source"]] : null)
  source_security_group_id = (can(cidrnetmask(each.value["source"])) ? null : each.value["source"])
  description              = try(each.value["description"], null)
  provider                 = aws.this
}

resource "aws_security_group_rule" "egress" {
  for_each                 = { for rule in var.security_group_rules : join(";", [rule.source]) => rule }
  security_group_id        = aws_security_group.this.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = "8086"
  to_port                  = "8086"
  cidr_blocks              = (can(cidrnetmask(each.value["source"])) ? [each.value["source"]] : null)
  source_security_group_id = (can(cidrnetmask(each.value["source"])) ? null : each.value["source"])
  description              = try(each.value["description"], null)
  provider                 = aws.this
}
