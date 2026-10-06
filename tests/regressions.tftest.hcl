# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_security_group" {
    defaults = { id = "sg-0000000000000000d", arn = "arn:aws:ec2:us-east-1:111111111111:security-group/sg-0000000000000000d" }
  }
  mock_resource "aws_timestreaminfluxdb_db_instance" {
    defaults = {
      arn                               = "arn:aws:timestream-influxdb:us-east-1:111111111111:db-instance/abcdefghij"
      endpoint                          = "abcdefghij-0123456789.us-east-1.timestream-influxdb.amazonaws.com"
      influx_auth_parameters_secret_arn = "arn:aws:secretsmanager:us-east-1:111111111111:secret:READONLY-InfluxDB-auth-parameters-abcdefghij-AbCdEf"
      port                              = 8086
    }
  }
}

mock_provider "random" {
  mock_resource "random_password" {
    defaults = { result = "Abcdefghijklmnopqrstuvwxyz012345" }
  }
}

variables {
  details          = { scope = "Test", purpose = "Time Series", environment = "test" }
  name             = "metrics"
  db_instance_type = "db.influx.medium"
  organization     = "engineering"
  bucket           = "metrics"
  vpc_id           = "vpc-0123456789abcdef0"
  subnet_ids       = ["subnet-0123456789abcdef0"]
}

# Regression tests for bugs in the module's earlier code.

# The ingress rules defaulted to null, and every plan without them failed with
# "Iteration over null value".
run "no_ingress_rules_plan" {
  command = plan
}

# The subnets were looked up by a Network tag, and every plan without the tag failed
# with "Invalid index". The given subnets are now used as they are.
run "subnet_ids_used_as_given" {
  command = plan
  variables {
    subnet_ids = ["subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb"]
  }
  assert {
    condition     = toset(aws_timestreaminfluxdb_db_instance.this.vpc_subnet_ids) == toset(["subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb"])
    error_message = "The subnets must be the ones given."
  }
}

# An IPv6 source was sent to AWS as a security group ID.
run "ipv6_source_is_a_cidr" {
  command = plan
  variables {
    security_group_ingress = { v6 = { cidr_ipv6 = "2600:1f18:1234:5600::/56" } }
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["v6"].cidr_ipv6 == "2600:1f18:1234:5600::/56" && aws_vpc_security_group_ingress_rule.this["v6"].referenced_security_group_id == null
    error_message = "An IPv6 range must be sent as cidr_ipv6."
  }
}

# Every ingress rule had a matching egress rule to the same source. The instance only
# answers connections, so the module creates no egress rules.
run "no_egress_rules" {
  command = plan
  variables {
    security_group_ingress = { vpc = { cidr_ipv4 = "10.0.0.0/16" } }
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["vpc"].from_port == 8086 && aws_vpc_security_group_ingress_rule.this["vpc"].to_port == 8086 && aws_vpc_security_group_ingress_rule.this["vpc"].ip_protocol == "tcp"
    error_message = "The rule must allow TCP 8086 only."
  }
}

# Two rules from the same source collided ("Duplicate object key"). Rules are now keyed
# by name.
run "two_rules_same_source" {
  command = plan
  variables {
    security_group_ingress = {
      office = { cidr_ipv4 = "10.0.0.0/8", description = "Office" }
      vpn    = { cidr_ipv4 = "10.1.0.0/16" }
    }
  }
  assert {
    condition     = aws_vpc_security_group_ingress_rule.this["vpn"].description == "vpn" && aws_vpc_security_group_ingress_rule.this["office"].description == "Office"
    error_message = "Each rule must be planned with its description, or its key."
  }
}

# The admin user name defaulted to null, which the provider refuses.
run "username_defaults_to_admin" {
  command = plan
  assert {
    condition     = aws_timestreaminfluxdb_db_instance.this.username == "admin"
    error_message = "username must default to admin."
  }
}

# A partial timeouts object failed with "Unsupported attribute".
run "partial_timeouts" {
  command = plan
  variables {
    timeouts = { create = "60m" }
  }
  assert {
    condition     = aws_timestreaminfluxdb_db_instance.this.timeouts.create == "60m" && aws_timestreaminfluxdb_db_instance.this.timeouts.update == "120m" && aws_timestreaminfluxdb_db_instance.this.timeouts.delete == "120m"
    error_message = "Missing timeouts must take their defaults."
  }
}

# The security group's description held the details and the Region. AWS cannot change
# a group's description, or an instance's groups, so a details change replaced the
# group and then the instance, deleting its data. Only the tags follow details now.
run "details_do_not_reach_security_group_name_or_description" {
  command = plan
  variables {
    details = { scope = "Other", purpose = "Other", environment = "other" }
  }
  assert {
    condition     = aws_security_group.this.description == "Timestream for InfluxDB instance metrics" && aws_security_group.this.name == "influxdb-metrics"
    error_message = "The group's name and description must depend only on name."
  }
  assert {
    condition     = aws_security_group.this.tags["Scope"] == "Other"
    error_message = "The details must still reach the group's tags."
  }
}
