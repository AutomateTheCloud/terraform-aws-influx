# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The security group of the instance. It allows the InfluxDB port from the sources in
# security_group_ingress and nothing else. It has no egress rules: the instance only
# answers connections, and security groups let replies out on their own. The AWS
# provider removes the rule that allows all outbound traffic, which AWS adds to every
# new group.
#
# AWS cannot change an instance's security groups, so a new group would replace the
# instance and delete its data. The group's name and description therefore depend only
# on var.name, which replaces the instance anyway. details reach the group only through
# its tags, which change in place.
resource "aws_security_group" "this" {
  region                 = var.region
  name                   = local.security_group_name
  description            = "Timestream for InfluxDB instance ${var.name}"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  tags = merge(local.tags, { Name = local.security_group_name })
}
