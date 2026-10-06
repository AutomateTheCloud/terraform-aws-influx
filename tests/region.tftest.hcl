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

# The module needs no providers block: it uses the default aws provider.
run "provider_region_by_default" {
  command = plan
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1" && output.metadata.aws.region.abbr == "use1"
    error_message = "Expected the provider's Region."
  }
}

run "region_reaches_every_resource" {
  command = apply
  variables {
    region                 = "us-west-2"
    security_group_ingress = { vpc = { cidr_ipv4 = "10.0.0.0/16" } }
  }
  assert {
    condition = alltrue([
      data.aws_region.this.region == "us-west-2",
      aws_security_group.this.region == "us-west-2",
      aws_vpc_security_group_ingress_rule.this["vpc"].region == "us-west-2",
      aws_timestreaminfluxdb_db_instance.this.region == "us-west-2",
    ])
    error_message = "region was not passed through to every resource."
  }
}
