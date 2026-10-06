# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "ap-southeast-7", description = "Asia Pacific (Thailand)" }
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

# Any Region plans, including ones missing from the old table and ones added after
# this module was written.
run "region_not_in_old_table" {
  command = plan
  variables { region = "ap-southeast-7" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7"
    error_message = "Unexpected abbreviation."
  }
}

run "mexico" {
  command = plan
  variables { region = "mx-central-1" }
  override_data {
    target = data.aws_region.this
    values = { region = "mx-central-1", description = "Mexico (Central)" }
  }
  assert {
    condition     = output.metadata.aws.region.abbr == "mxc1"
    error_message = "Unexpected abbreviation."
  }
}

run "govcloud" {
  command = plan
  variables { region = "us-gov-west-1" }
  override_data {
    target = data.aws_region.this
    values = { region = "us-gov-west-1", description = "AWS GovCloud (US-West)" }
  }
  assert {
    condition     = output.metadata.aws.region.abbr == "ugw1"
    error_message = "Unexpected abbreviation."
  }
}
