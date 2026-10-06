# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A private InfluxDB instance in the subnets you give, reachable on port 8086 from
# anywhere in the VPC. The module creates the admin password, and AWS keeps a copy in
# AWS Secrets Manager.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC to create the instance in"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of 1 to 3 private subnets of the VPC for the instance"
  type        = list(string)
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

module "influxdb" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "Metrics"
    environment = "Development"
  }

  name             = "example-basic"
  db_instance_type = "db.influx.medium"
  organization     = "example"
  bucket           = "metrics"
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids

  security_group_ingress = {
    vpc = { cidr_ipv4 = data.aws_vpc.this.cidr_block, description = "Anything in the VPC" }
  }
}

output "influxdb" {
  description = "Where to connect, and the ARN of the Secrets Manager secret that holds the admin user name and password"
  value = {
    url        = "https://${module.influxdb.metadata.timestreaminfluxdb_db_instance.endpoint}:${module.influxdb.metadata.timestreaminfluxdb_db_instance.port}"
    secret_arn = module.influxdb.metadata.timestreaminfluxdb_db_instance.influx_auth_parameters_secret_arn
  }
}
