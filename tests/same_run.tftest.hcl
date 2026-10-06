# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_resource "aws_vpc" {
    defaults = { id = "vpc-0123456789abcdef0" }
  }
  mock_resource "aws_subnet" {
    defaults = { id = "subnet-0123456789abcdef0" }
  }
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

# The VPC, subnets and client security group are created in the same run, so their IDs
# are unknown when the module plans. The rules are decided from the input's keys, so the
# plan succeeds.
run "same_run_plan" {
  command = plan
  module {
    source = "./tests/fixtures/same_run"
  }
  assert {
    condition     = toset(keys(module.influxdb.metadata.vpc_security_group_ingress_rule)) == toset(["app", "vpc"])
    error_message = "Both rules must be planned."
  }
}

run "same_run_apply" {
  command = apply
  module {
    source = "./tests/fixtures/same_run"
  }
  assert {
    condition     = output.metadata.vpc_security_group_ingress_rule["app"].referenced_security_group_id == aws_security_group.app.id && output.metadata.security_group.vpc_id == aws_vpc.this.id
    error_message = "The same-run security group and VPC must reach the module."
  }
}
