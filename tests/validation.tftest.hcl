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

# Each validation refuses what AWS or the provider would refuse, at plan time.

run "details_scope_empty" {
  command = plan
  variables {
    details = { scope = " ", purpose = "p", environment = "e" }
  }
  expect_failures = [var.details]
}

run "details_purpose_empty" {
  command = plan
  variables {
    details = { scope = "s", purpose = "", environment = "e" }
  }
  expect_failures = [var.details]
}

run "details_environment_empty" {
  command = plan
  variables {
    details = { scope = "s", purpose = "p", environment = "" }
  }
  expect_failures = [var.details]
}

run "name_too_short" {
  command = plan
  variables {
    name = "ab"
  }
  expect_failures = [var.name]
}

run "name_too_long" {
  command = plan
  variables {
    name = "a234567890123456789012345678901234567890x"
  }
  expect_failures = [var.name]
}

run "name_starts_with_digit" {
  command = plan
  variables {
    name = "1metrics"
  }
  expect_failures = [var.name]
}

run "name_double_hyphen" {
  command = plan
  variables {
    name = "met--rics"
  }
  expect_failures = [var.name]
}

run "name_trailing_hyphen" {
  command = plan
  variables {
    name = "metrics-"
  }
  expect_failures = [var.name]
}

run "name_underscore" {
  command = plan
  variables {
    name = "met_rics"
  }
  expect_failures = [var.name]
}

run "db_instance_type_unknown" {
  command = plan
  variables {
    db_instance_type = "db.t3.micro"
  }
  expect_failures = [var.db_instance_type]
}

run "organization_empty" {
  command = plan
  variables {
    organization = ""
  }
  expect_failures = [var.organization]
}

run "organization_too_long" {
  command = plan
  variables {
    organization = "a2345678901234567890123456789012345678901234567890123456789012345"
  }
  expect_failures = [var.organization]
}

run "bucket_too_short" {
  command = plan
  variables {
    bucket = "a"
  }
  expect_failures = [var.bucket]
}

run "bucket_underscore_first" {
  command = plan
  variables {
    bucket = "_metrics"
  }
  expect_failures = [var.bucket]
}

run "bucket_double_quote" {
  command = plan
  variables {
    bucket = "met\"rics"
  }
  expect_failures = [var.bucket]
}

run "username_digit_first" {
  command = plan
  variables {
    username = "1admin"
  }
  expect_failures = [var.username]
}

run "username_trailing_hyphen" {
  command = plan
  variables {
    username = "admin-"
  }
  expect_failures = [var.username]
}

run "username_double_hyphen" {
  command = plan
  variables {
    username = "ad--min"
  }
  expect_failures = [var.username]
}

run "username_too_long" {
  command = plan
  variables {
    username = "a2345678901234567890123456789012345678901234567890123456789012345"
  }
  expect_failures = [var.username]
}

run "password_too_short" {
  command = plan
  variables {
    password = "Abc1234"
  }
  expect_failures = [var.password]
}

run "password_special" {
  command = plan
  variables {
    password = "Abcdefgh1!"
  }
  expect_failures = [var.password]
}

run "password_too_long" {
  command = plan
  variables {
    password = "a2345678901234567890123456789012345678901234567890123456789012345"
  }
  expect_failures = [var.password]
}

run "vpc_id_not_vpc" {
  command = plan
  variables {
    vpc_id = "subnet-0123456789abcdef0"
  }
  expect_failures = [var.vpc_id]
}

run "subnet_ids_empty" {
  command = plan
  variables {
    subnet_ids = []
  }
  expect_failures = [var.subnet_ids]
}

run "subnet_ids_four" {
  command = plan
  variables {
    subnet_ids = ["subnet-01", "subnet-02", "subnet-03", "subnet-04"]
  }
  expect_failures = [var.subnet_ids]
}

run "subnet_ids_not_subnet" {
  command = plan
  variables {
    subnet_ids = ["sg-0123456789abcdef0"]
  }
  expect_failures = [var.subnet_ids]
}

run "multi_az_one_subnet" {
  command = plan
  variables {
    multi_az = true
  }
  expect_failures = [var.multi_az]
}

run "additional_sg_five" {
  command = plan
  variables {
    additional_security_group_ids = ["sg-01", "sg-02", "sg-03", "sg-04", "sg-05"]
  }
  expect_failures = [var.additional_security_group_ids]
}

run "additional_sg_not_sg" {
  command = plan
  variables {
    additional_security_group_ids = ["vpc-0123456789abcdef0"]
  }
  expect_failures = [var.additional_security_group_ids]
}

run "storage_type_unknown" {
  command = plan
  variables {
    storage = { type = "gp3" }
  }
  expect_failures = [var.storage]
}

run "storage_too_small" {
  command = plan
  variables {
    storage = { allocated = 19 }
  }
  expect_failures = [var.storage]
}

run "storage_too_large" {
  command = plan
  variables {
    storage = { allocated = 15361 }
  }
  expect_failures = [var.storage]
}

run "storage_fraction" {
  command = plan
  variables {
    storage = { allocated = 20.5 }
  }
  expect_failures = [var.storage]
}

run "storage_t2_too_small" {
  command = plan
  variables {
    storage = { type = "InfluxIOIncludedT2", allocated = 399 }
  }
  expect_failures = [var.storage]
}

run "storage_t3_default_size" {
  command = plan
  variables {
    storage = { type = "InfluxIOIncludedT3" }
  }
  expect_failures = [var.storage]
}

run "port_too_low" {
  command = plan
  variables {
    port = 1023
  }
  expect_failures = [var.port]
}

run "port_too_high" {
  command = plan
  variables {
    port = 65536
  }
  expect_failures = [var.port]
}

run "port_reserved" {
  command = plan
  variables {
    port = 8090
  }
  expect_failures = [var.port]
}

run "port_reserved_range" {
  command = plan
  variables {
    port = 7795
  }
  expect_failures = [var.port]
}

run "network_type_unknown" {
  command = plan
  variables {
    network_type = "IPV6"
  }
  expect_failures = [var.network_type]
}

run "parameter_group_short" {
  command = plan
  variables {
    db_parameter_group_identifier = "ab"
  }
  expect_failures = [var.db_parameter_group_identifier]
}

run "parameter_group_hyphen" {
  command = plan
  variables {
    db_parameter_group_identifier = "my-group"
  }
  expect_failures = [var.db_parameter_group_identifier]
}

run "log_bucket_upper" {
  command = plan
  variables {
    log_delivery = { s3_bucket_name = "My-Logs" }
  }
  expect_failures = [var.log_delivery]
}


run "ingress_no_source" {
  command = plan
  variables {
    security_group_ingress = { a = { description = "none" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_two_sources" {
  command = plan
  variables {
    security_group_ingress = { a = { cidr_ipv4 = "10.0.0.0/8", security_group_id = "sg-0123456789abcdef0" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_ipv6_in_ipv4" {
  command = plan
  variables {
    security_group_ingress = { a = { cidr_ipv4 = "2600:1f18::/32" } }
  }
  expect_failures = [var.security_group_ingress]
}

run "ingress_ipv4_in_ipv6" {
  command = plan
  variables {
    security_group_ingress = { a = { cidr_ipv6 = "10.0.0.0/8" } }
  }
  expect_failures = [var.security_group_ingress]
}

# The edges that AWS accepts pass.
run "accepted_edges" {
  command = plan
  variables {
    name                          = "A23456789012345678901234567890123456789x"
    username                      = "a"
    password                      = "Abcdefg1"
    bucket                        = "ab"
    organization                  = "o"
    port                          = 1024
    subnet_ids                    = ["subnet-01", "subnet-02", "subnet-03"]
    multi_az                      = true
    additional_security_group_ids = ["sg-01", "sg-02", "sg-03", "sg-04"]
    storage                       = { type = "InfluxIOIncludedT3", allocated = 15360 }
    db_parameter_group_identifier = "abc"
    network_type                  = "DUAL"
    log_delivery                  = { s3_bucket_name = "abc" }
  }
}
