# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_timestreaminfluxdb_db_instance" "this" {
  region = var.region
  name   = var.name

  db_instance_type              = var.db_instance_type
  deployment_type               = var.multi_az ? "WITH_MULTIAZ_STANDBY" : "SINGLE_AZ"
  db_storage_type               = var.storage.type
  allocated_storage             = var.storage.allocated
  db_parameter_group_identifier = var.db_parameter_group_identifier
  port                          = var.port

  # The initial admin user, organization and bucket. See lifecycle below.
  username     = var.username
  password     = local.password_given ? var.password : random_password.this[0].result
  organization = var.organization
  bucket       = var.bucket

  publicly_accessible    = var.publicly_accessible
  network_type           = var.network_type
  vpc_subnet_ids         = var.subnet_ids
  vpc_security_group_ids = concat([aws_security_group.this.id], var.additional_security_group_ids)

  dynamic "log_delivery_configuration" {
    for_each = var.log_delivery == null ? [] : [var.log_delivery]
    content {
      s3_configuration {
        bucket_name = log_delivery_configuration.value.s3_bucket_name
        enabled     = log_delivery_configuration.value.enabled
      }
    }
  }

  tags = merge(local.tags, { Name = var.name })

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  # AWS uses these only to set up InfluxDB when it creates the instance. A change to any
  # of them would replace the instance and delete its data, so later changes are
  # ignored; they are made inside InfluxDB instead.
  lifecycle {
    ignore_changes = [username, password, organization, bucket]
  }
}
