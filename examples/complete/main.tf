# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Most of the module's options: a standby in a second Availability Zone, more storage,
# access from one security group only, and the InfluxDB logs delivered to a private S3
# bucket.

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
  description = "IDs of 2 or 3 private subnets of the VPC, in different Availability Zones"
  type        = list(string)
}

locals {
  details = {
    scope           = "Example"
    purpose         = "Metrics"
    environment     = "Production"
    additional_tags = { CostCenter = "1234" }
  }
}

# The clients: attach this group to the instances or tasks that write and read metrics.
resource "aws_security_group" "clients" {
  name        = "example-complete-influxdb-clients"
  description = "Clients of the example-complete InfluxDB instance"
  vpc_id      = var.vpc_id
}

# A private bucket for the InfluxDB logs. force_destroy lets terraform destroy delete
# it with the logs in it; remove it to keep the logs.
resource "aws_s3_bucket" "logs" {
  bucket_prefix = "example-complete-influxdb-logs-"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Timestream for InfluxDB writes the logs under InfluxLogs/. This is the policy the AWS
# documentation gives. AWS checks it when it creates the instance, and refuses one with
# an aws:SourceAccount condition ("invalid bucket policy").
data "aws_iam_policy_document" "logs" {
  statement {
    sid       = "InfluxDBLogDelivery"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/InfluxLogs/*"]
    principals {
      type        = "Service"
      identifiers = ["timestream-influxdb.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs.json

  depends_on = [aws_s3_bucket_public_access_block.logs]
}

module "influxdb" {
  source = "../../"

  details = local.details

  name             = "example-complete"
  db_instance_type = "db.influx.medium"
  multi_az         = true
  storage          = { type = "InfluxIOIncludedT1", allocated = 50 }
  organization     = "example"
  bucket           = "metrics"
  username         = "influxadmin"
  vpc_id           = var.vpc_id
  subnet_ids       = var.subnet_ids

  security_group_ingress = {
    clients = { security_group_id = aws_security_group.clients.id, description = "InfluxDB clients" }
  }

  # Taken from the bucket policy, not the bucket, so the policy exists before AWS
  # checks it, when it creates the instance.
  log_delivery = { s3_bucket_name = aws_s3_bucket_policy.logs.bucket }
}

output "influxdb" {
  description = "Where to connect, the ARN of the Secrets Manager secret that holds the admin user name and password, the clients' security group, and the log bucket"
  value = {
    url                       = "https://${module.influxdb.metadata.timestreaminfluxdb_db_instance.endpoint}:${module.influxdb.metadata.timestreaminfluxdb_db_instance.port}"
    secret_arn                = module.influxdb.metadata.timestreaminfluxdb_db_instance.influx_auth_parameters_secret_arn
    clients_security_group_id = aws_security_group.clients.id
    log_bucket                = aws_s3_bucket.logs.id
  }
}
