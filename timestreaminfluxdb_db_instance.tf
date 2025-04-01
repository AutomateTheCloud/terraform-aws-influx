resource "aws_timestreaminfluxdb_db_instance" "this" {
  name = var.name

  db_instance_type = var.db_instance_type
  deployment_type  = (var.multi_az ? "WITH_MULTIAZ_STANDBY" : "SINGLE_AZ")

  db_storage_type   = var.storage_type
  allocated_storage = var.storage_size

  bucket       = var.bucket
  organization = var.organization

  username = try(var.credentials.username, null)
  password = local.database_password

  db_parameter_group_identifier = try(var.db_parameter_group_identifier, null)

  publicly_accessible    = var.publicly_accessible
  vpc_subnet_ids         = local.subnets
  vpc_security_group_ids = concat([aws_security_group.this.id], var.security_groups_additional)

  tags = merge(
    local.tags,
    tomap({
      "Name" = var.name
    })
  )

  lifecycle {
    ignore_changes = [
      password
    ]
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  provider = aws.this
}
