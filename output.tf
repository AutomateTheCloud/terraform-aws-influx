output "metadata" {
  description = "Metadata"
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    timestreaminfluxdb_db_instance = {
      allocated_storage                 = try(aws_timestreaminfluxdb_db_instance.this.allocated_storage, null)
      arn                               = try(aws_timestreaminfluxdb_db_instance.this.arn, null)
      availability_zone                 = try(aws_timestreaminfluxdb_db_instance.this.availability_zone, null)
      bucket                            = try(aws_timestreaminfluxdb_db_instance.this.bucket, null)
      db_instance_type                  = try(aws_timestreaminfluxdb_db_instance.this.db_instance_type, null)
      db_parameter_group_identifier     = try(aws_timestreaminfluxdb_db_instance.this.db_parameter_group_identifier, null)
      db_storage_type                   = try(aws_timestreaminfluxdb_db_instance.this.db_storage_type, null)
      endpoint                          = try(aws_timestreaminfluxdb_db_instance.this.endpoint, null)
      id                                = try(aws_timestreaminfluxdb_db_instance.this.id, null)
      influx_auth_parameters_secret_arn = try(aws_timestreaminfluxdb_db_instance.this.influx_auth_parameters_secret_arn, null)
      log_delivery_configuration        = try(aws_timestreaminfluxdb_db_instance.this.log_delivery_configuration, null)
      name                              = try(aws_timestreaminfluxdb_db_instance.this.name, null)
      organization                      = try(aws_timestreaminfluxdb_db_instance.this.organization, null)
      publicly_accessible               = try(aws_timestreaminfluxdb_db_instance.this.publicly_accessible, null)
      secondary_availability_zone       = try(aws_timestreaminfluxdb_db_instance.this.secondary_availability_zone, null)
      tags                              = try(aws_timestreaminfluxdb_db_instance.this.tags, null)
      username                          = try(aws_timestreaminfluxdb_db_instance.this.username, null)
      vpc_security_group_ids            = try(aws_timestreaminfluxdb_db_instance.this.vpc_security_group_ids, null)
      vpc_subnet_ids                    = try(aws_timestreaminfluxdb_db_instance.this.vpc_subnet_ids, null)
    }

    security_group = try(aws_security_group.this, null)
  }
}
