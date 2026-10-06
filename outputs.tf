# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
    - `timestreaminfluxdb_db_instance` - The database instance: its `endpoint` (the host name clients connect to, over HTTPS), `port`, `arn`, `id`, `influx_auth_parameters_secret_arn` (the AWS Secrets Manager secret that AWS created with the admin user name and password), and the rest of its attributes. The password is left out. `availability_zone` and `secondary_availability_zone` are the names AWS reports, which can differ from the names of the same zones in your account: an instance in subnets in `us-east-1a` and `us-east-1b` was reported in `us-east-1d` and `us-east-1c`. `vpc_subnet_ids` shows where it really is.
    - `security_group` - The instance's security group, with its `id`, `arn` and `name`.
    - `vpc_security_group_ingress_rule` - The ingress rules, keyed like `security_group_ingress`, or `null` when there are none.
  EOT
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

    # One entry per resource. Resources that are not created are null.
    security_group                  = local.output_resources.security_group
    timestreaminfluxdb_db_instance  = local.output_resources.timestreaminfluxdb_db_instance
    vpc_security_group_ingress_rule = local.output_resources.vpc_security_group_ingress_rule
  }
}

locals {
  # Each resource's attributes are listed one by one. Referencing a whole resource, or
  # iterating over it, would also reference its deprecated and sensitive attributes
  # (the instance's password), and every caller's plan would print deprecation warnings
  # or the output would become sensitive. Keyed resources are indexed from the inputs
  # for the same reason. The security group's inline ingress and egress are left out:
  # they are read before the separate rules are attached, so the next plan would show
  # the output changing.
  output_resources = {
    timestreaminfluxdb_db_instance = {
      allocated_storage                 = aws_timestreaminfluxdb_db_instance.this.allocated_storage
      arn                               = aws_timestreaminfluxdb_db_instance.this.arn
      availability_zone                 = aws_timestreaminfluxdb_db_instance.this.availability_zone
      bucket                            = aws_timestreaminfluxdb_db_instance.this.bucket
      db_instance_type                  = aws_timestreaminfluxdb_db_instance.this.db_instance_type
      db_parameter_group_identifier     = aws_timestreaminfluxdb_db_instance.this.db_parameter_group_identifier
      db_storage_type                   = aws_timestreaminfluxdb_db_instance.this.db_storage_type
      deployment_type                   = aws_timestreaminfluxdb_db_instance.this.deployment_type
      endpoint                          = aws_timestreaminfluxdb_db_instance.this.endpoint
      id                                = aws_timestreaminfluxdb_db_instance.this.id
      influx_auth_parameters_secret_arn = aws_timestreaminfluxdb_db_instance.this.influx_auth_parameters_secret_arn
      log_delivery_configuration        = aws_timestreaminfluxdb_db_instance.this.log_delivery_configuration
      name                              = aws_timestreaminfluxdb_db_instance.this.name
      network_type                      = aws_timestreaminfluxdb_db_instance.this.network_type
      organization                      = aws_timestreaminfluxdb_db_instance.this.organization
      port                              = aws_timestreaminfluxdb_db_instance.this.port
      publicly_accessible               = aws_timestreaminfluxdb_db_instance.this.publicly_accessible
      region                            = aws_timestreaminfluxdb_db_instance.this.region
      secondary_availability_zone       = aws_timestreaminfluxdb_db_instance.this.secondary_availability_zone
      tags                              = aws_timestreaminfluxdb_db_instance.this.tags
      tags_all                          = aws_timestreaminfluxdb_db_instance.this.tags_all
      username                          = aws_timestreaminfluxdb_db_instance.this.username
      vpc_security_group_ids            = aws_timestreaminfluxdb_db_instance.this.vpc_security_group_ids
      vpc_subnet_ids                    = aws_timestreaminfluxdb_db_instance.this.vpc_subnet_ids
    }
    security_group = {
      arn                    = aws_security_group.this.arn
      description            = aws_security_group.this.description
      id                     = aws_security_group.this.id
      name                   = aws_security_group.this.name
      name_prefix            = aws_security_group.this.name_prefix
      owner_id               = aws_security_group.this.owner_id
      region                 = aws_security_group.this.region
      revoke_rules_on_delete = aws_security_group.this.revoke_rules_on_delete
      tags                   = aws_security_group.this.tags
      tags_all               = aws_security_group.this.tags_all
      vpc_id                 = aws_security_group.this.vpc_id
    }
    vpc_security_group_ingress_rule = length(var.security_group_ingress) == 0 ? null : {
      for k in keys(var.security_group_ingress) : k => {
        arn                          = aws_vpc_security_group_ingress_rule.this[k].arn
        cidr_ipv4                    = aws_vpc_security_group_ingress_rule.this[k].cidr_ipv4
        cidr_ipv6                    = aws_vpc_security_group_ingress_rule.this[k].cidr_ipv6
        description                  = aws_vpc_security_group_ingress_rule.this[k].description
        from_port                    = aws_vpc_security_group_ingress_rule.this[k].from_port
        id                           = aws_vpc_security_group_ingress_rule.this[k].id
        ip_protocol                  = aws_vpc_security_group_ingress_rule.this[k].ip_protocol
        prefix_list_id               = aws_vpc_security_group_ingress_rule.this[k].prefix_list_id
        referenced_security_group_id = aws_vpc_security_group_ingress_rule.this[k].referenced_security_group_id
        region                       = aws_vpc_security_group_ingress_rule.this[k].region
        security_group_id            = aws_vpc_security_group_ingress_rule.this[k].security_group_id
        security_group_rule_id       = aws_vpc_security_group_ingress_rule.this[k].security_group_rule_id
        tags                         = aws_vpc_security_group_ingress_rule.this[k].tags
        tags_all                     = aws_vpc_security_group_ingress_rule.this[k].tags_all
        to_port                      = aws_vpc_security_group_ingress_rule.this[k].to_port
      }
    }
  }
}
