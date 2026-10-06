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

run "multi_az" {
  command = plan
  variables {
    multi_az   = true
    subnet_ids = ["subnet-0aaaaaaaaaaaaaaaa", "subnet-0bbbbbbbbbbbbbbbb"]
  }
  assert {
    condition     = aws_timestreaminfluxdb_db_instance.this.deployment_type == "WITH_MULTIAZ_STANDBY"
    error_message = "multi_az must ask for a standby."
  }
}

run "port_reaches_instance_and_rules" {
  command = plan
  variables {
    port                   = 9086
    security_group_ingress = { vpc = { cidr_ipv4 = "10.0.0.0/16" } }
  }
  assert {
    condition     = aws_timestreaminfluxdb_db_instance.this.port == 9086 && aws_vpc_security_group_ingress_rule.this["vpc"].from_port == 9086 && aws_vpc_security_group_ingress_rule.this["vpc"].to_port == 9086
    error_message = "The port must reach the instance and the rules."
  }
}

run "every_source_kind" {
  command = plan
  variables {
    security_group_ingress = {
      v4  = { cidr_ipv4 = "10.0.0.0/16" }
      v6  = { cidr_ipv6 = "2600:1f18:1234:5600::/56" }
      app = { security_group_id = "sg-0123456789abcdef0", description = "Application servers" }
      pl  = { prefix_list_id = "pl-0123456789abcdef0" }
    }
  }
  assert {
    condition = alltrue([
      aws_vpc_security_group_ingress_rule.this["v4"].cidr_ipv4 == "10.0.0.0/16",
      aws_vpc_security_group_ingress_rule.this["v6"].cidr_ipv6 == "2600:1f18:1234:5600::/56",
      aws_vpc_security_group_ingress_rule.this["app"].referenced_security_group_id == "sg-0123456789abcdef0",
      aws_vpc_security_group_ingress_rule.this["app"].description == "Application servers",
      aws_vpc_security_group_ingress_rule.this["pl"].prefix_list_id == "pl-0123456789abcdef0",
      aws_vpc_security_group_ingress_rule.this["pl"].tags["Name"] == "influxdb-metrics-pl",
    ])
    error_message = "Each source must reach its own argument."
  }
}

run "storage_and_parameter_group_and_network" {
  command = plan
  variables {
    storage                       = { type = "InfluxIOIncludedT2", allocated = 400 }
    db_parameter_group_identifier = "mygroup"
    network_type                  = "DUAL"
    publicly_accessible           = true
  }
  assert {
    condition = alltrue([
      aws_timestreaminfluxdb_db_instance.this.db_storage_type == "InfluxIOIncludedT2",
      aws_timestreaminfluxdb_db_instance.this.allocated_storage == 400,
      aws_timestreaminfluxdb_db_instance.this.db_parameter_group_identifier == "mygroup",
      aws_timestreaminfluxdb_db_instance.this.network_type == "DUAL",
      aws_timestreaminfluxdb_db_instance.this.publicly_accessible == true,
    ])
    error_message = "The inputs must reach the instance."
  }
}

run "log_delivery_on" {
  command = plan
  variables {
    log_delivery = { s3_bucket_name = "my-influx-logs" }
  }
  assert {
    condition     = aws_timestreaminfluxdb_db_instance.this.log_delivery_configuration[0].s3_configuration[0].bucket_name == "my-influx-logs" && aws_timestreaminfluxdb_db_instance.this.log_delivery_configuration[0].s3_configuration[0].enabled == true
    error_message = "Log delivery must be on."
  }
}

run "log_delivery_off" {
  command = plan
  variables {
    log_delivery = { s3_bucket_name = "my-influx-logs", enabled = false }
  }
  assert {
    condition     = aws_timestreaminfluxdb_db_instance.this.log_delivery_configuration[0].s3_configuration[0].enabled == false
    error_message = "enabled = false must be sent."
  }
}

# A given password is used, no password is generated, and the output stays usable:
# the variable is sensitive, and its mark must not reach metadata.
run "password_given" {
  command = apply
  variables {
    password = "Givenpassword123"
  }
  assert {
    condition     = length(random_password.this) == 0 && nonsensitive(aws_timestreaminfluxdb_db_instance.this.password == "Givenpassword123")
    error_message = "The given password must be used, and none generated."
  }
  assert {
    condition     = !issensitive(output.metadata)
    error_message = "metadata must not be sensitive."
  }
}

# The password is used only at create: a later change leaves the instance alone, since
# the provider could apply it only by replacing the instance.
run "password_change_ignored" {
  command = plan
  variables {
    password = "Otherpassword123"
  }
  assert {
    condition     = nonsensitive(aws_timestreaminfluxdb_db_instance.this.password == "Givenpassword123")
    error_message = "A later password change must be ignored."
  }
}

run "additional_security_groups" {
  command = apply
  variables {
    additional_security_group_ids = ["sg-0123456789abcdef0"]
  }
  assert {
    condition     = toset(aws_timestreaminfluxdb_db_instance.this.vpc_security_group_ids) == toset(["sg-0000000000000000d", "sg-0123456789abcdef0"])
    error_message = "The module's group and the additional one must be attached."
  }
}
