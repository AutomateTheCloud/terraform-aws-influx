# Copyright 2026 Automate the Cloud Inc.
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

# With only the required inputs: private, IPv4, one Availability Zone, the smallest
# storage, an admin user named admin with a generated password, no logs, and a
# security group that lets nothing in or out.
run "defaults" {
  command = plan

  assert {
    condition = alltrue([
      aws_timestreaminfluxdb_db_instance.this.publicly_accessible == false,
      aws_timestreaminfluxdb_db_instance.this.deployment_type == "SINGLE_AZ",
      aws_timestreaminfluxdb_db_instance.this.db_storage_type == "InfluxIOIncludedT1",
      aws_timestreaminfluxdb_db_instance.this.allocated_storage == 20,
      aws_timestreaminfluxdb_db_instance.this.username == "admin",
      aws_timestreaminfluxdb_db_instance.this.organization == "engineering",
      aws_timestreaminfluxdb_db_instance.this.bucket == "metrics",
      aws_timestreaminfluxdb_db_instance.this.db_parameter_group_identifier == null,
      length(aws_timestreaminfluxdb_db_instance.this.log_delivery_configuration) == 0,
      toset(aws_timestreaminfluxdb_db_instance.this.vpc_subnet_ids) == toset(["subnet-0123456789abcdef0"]),
    ])
    error_message = "The instance does not have the expected defaults."
  }

  assert {
    condition     = length(random_password.this) == 1 && random_password.this[0].length == 32 && random_password.this[0].special == false
    error_message = "A 32-character password of letters and digits must be generated."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 0 && output.metadata.vpc_security_group_ingress_rule == null
    error_message = "No ingress rule may exist by default."
  }

  assert {
    condition     = aws_security_group.this.name == "influxdb-metrics" && aws_security_group.this.vpc_id == "vpc-0123456789abcdef0"
    error_message = "Unexpected security group."
  }

  assert {
    condition     = aws_timestreaminfluxdb_db_instance.this.tags == tomap({ Scope = "Test", Purpose = "Time Series", Environment = "test", Name = "metrics" })
    error_message = "The details tags must be applied."
  }
}

run "defaults_apply" {
  command = apply

  assert {
    condition     = nonsensitive(aws_timestreaminfluxdb_db_instance.this.password == "Abcdefghijklmnopqrstuvwxyz012345")
    error_message = "The generated password must be used."
  }

  assert {
    condition     = toset(aws_timestreaminfluxdb_db_instance.this.vpc_security_group_ids) == toset(["sg-0000000000000000d"])
    error_message = "Only the module's security group may be attached by default."
  }

  assert {
    condition     = output.metadata.timestreaminfluxdb_db_instance.endpoint == "abcdefghij-0123456789.us-east-1.timestream-influxdb.amazonaws.com" && output.metadata.security_group.id == "sg-0000000000000000d"
    error_message = "metadata must carry the instance and the security group."
  }

  assert {
    condition     = !issensitive(output.metadata) && !contains(keys(output.metadata.timestreaminfluxdb_db_instance), "password")
    error_message = "metadata must not be sensitive and must not hold the password."
  }
}
