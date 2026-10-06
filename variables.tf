# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "additional_security_group_ids" {
  description = <<-EOT
    More security groups to attach to the database instance, beside the one the module creates, such as `["sg-0123456789abcdef0"]`. At most 4: AWS allows 5 per instance. Choose them before you create the instance: AWS cannot change an instance's security groups, so any change to this list replaces the instance and deletes its data.
  EOT
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = length(var.additional_security_group_ids) <= 4
    error_message = "additional_security_group_ids can have at most 4 entries: AWS allows 5 security groups per instance, and the module creates one."
  }

  validation {
    condition     = alltrue([for id in var.additional_security_group_ids : can(regex("^sg-[a-z0-9]+$", id))])
    error_message = "Each entry in additional_security_group_ids must be a security group ID, such as sg-0123456789abcdef0."
  }
}

variable "bucket" {
  description = <<-EOT
    The name of the first InfluxDB bucket, which AWS creates in `organization` with the instance, such as `metrics`. A bucket holds time series data and how long to keep it. 2 to 64 characters, not starting with an underscore, with no double quotes. Create more buckets inside InfluxDB.

    AWS uses it only when it creates the instance, so the module ignores later changes to it (see `username`).
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = length(var.bucket) >= 2 && length(var.bucket) <= 64 && can(regex("^[^_\"][^\"]*$", var.bucket))
    error_message = "bucket must be 2 to 64 characters, not start with an underscore, and contain no double quotes."
  }
}

variable "db_instance_type" {
  description = <<-EOT
    The instance type, which sets the CPU and memory: `db.influx.medium`, `db.influx.large`, `db.influx.xlarge`, `db.influx.2xlarge`, `db.influx.4xlarge`, `db.influx.8xlarge`, `db.influx.12xlarge`, `db.influx.16xlarge` or `db.influx.24xlarge`. `db.influx.medium` is the smallest. `db.influx.24xlarge` needs AWS provider 6.5.0 or later; older versions refuse it at plan. Changing it later resizes the instance in place; see the README for what to expect with `multi_az`.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = contains(["db.influx.medium", "db.influx.large", "db.influx.xlarge", "db.influx.2xlarge", "db.influx.4xlarge", "db.influx.8xlarge", "db.influx.12xlarge", "db.influx.16xlarge", "db.influx.24xlarge"], var.db_instance_type)
    error_message = "db_instance_type must be db.influx.medium, db.influx.large, db.influx.xlarge, db.influx.2xlarge, db.influx.4xlarge, db.influx.8xlarge, db.influx.12xlarge, db.influx.16xlarge or db.influx.24xlarge."
  }
}

variable "db_parameter_group_identifier" {
  description = <<-EOT
    The ID of a DB parameter group with InfluxDB engine settings, such as the log level or query limits. The AWS provider has no resource for these groups; create one with the AWS CLI (`aws timestream-influxdb create-db-parameter-group`) or the console. AWS cannot delete a parameter group once it exists. Without it, InfluxDB uses its default settings.

    Setting or changing it later is done in place and restarts the instance. Removing it replaces the instance and deletes its data.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.db_parameter_group_identifier == null || can(regex("^[A-Za-z0-9]{3,64}$", coalesce(var.db_parameter_group_identifier, "-")))
    error_message = "db_parameter_group_identifier must be 3 to 64 letters and digits."
  }
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-influx#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "log_delivery" {
  description = <<-EOT
    Send the InfluxDB engine logs to an Amazon S3 bucket, under the `InfluxLogs/` prefix; AWS documents hourly delivery. The bucket must be in the same account and Region as the instance, and its bucket policy must let the `timestream-influxdb.amazonaws.com` service principal call `s3:PutObject` on `<bucket ARN>/InfluxLogs/*`. AWS checks the policy when it creates the instance, and refused one whose statement also required `aws:SourceAccount`; [`examples/complete`](https://github.com/AutomateTheCloud/terraform-aws-influx/tree/main/examples/complete) shows one. With the default, `null`, no logs are delivered.

    - `s3_bucket_name` - (Required) The name of the bucket.
    - `enabled` - (Optional) Deliver logs. Defaults to `true`. To stop delivery, set it to `false` and apply, and keep `log_delivery`: removing it after it has been set makes the apply fail (`At least one updatable parameter must be set`).
  EOT
  type = object({
    s3_bucket_name = string
    enabled        = optional(bool, true)
  })
  default = null

  validation {
    condition     = var.log_delivery == null || can(regex("^[0-9a-z][0-9a-z.-]{1,61}[0-9a-z]$", try(var.log_delivery.s3_bucket_name, "")))
    error_message = "log_delivery.s3_bucket_name must be an S3 bucket name: 3 to 63 lowercase letters, digits, dots and hyphens, starting and ending with a letter or digit."
  }
}

variable "multi_az" {
  description = <<-EOT
    Keep a standby instance in another Availability Zone, which AWS fails over to when the primary or its zone fails. It needs `subnet_ids` in at least two Availability Zones, and about doubles the cost. Defaults to `false`. Turning it on or off later is done in place.
  EOT
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = !var.multi_az || length(var.subnet_ids) >= 2
    error_message = "multi_az needs at least two subnet_ids, in different Availability Zones."
  }
}

variable "name" {
  description = <<-EOT
    The name of the database instance, such as `metrics-production`: 3 to 40 letters, digits and hyphens, starting with a letter, with no two hyphens in a row and no hyphen at the end. It must be unique among the account's instances in the Region, and starts the instance's endpoint address. The security group is named `influxdb-<name>`.

    Changing it later replaces the instance and deletes its data.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 40 && can(regex("^[A-Za-z][A-Za-z0-9]*(-[A-Za-z0-9]+)*$", var.name))
    error_message = "name must be 3 to 40 letters, digits and hyphens, start with a letter, and have no two hyphens in a row and no hyphen at the end."
  }
}

variable "network_type" {
  description = <<-EOT
    The IP protocols clients can use to reach the instance: `IPV4`, or `DUAL` for IPv4 and IPv6. `DUAL` needs subnets with IPv6 ranges. Without it, AWS uses `IPV4`. Changing it later replaces the instance and deletes its data.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.network_type == null || contains(["IPV4", "DUAL"], coalesce(var.network_type, "-"))
    error_message = "network_type must be IPV4 or DUAL."
  }
}

variable "organization" {
  description = <<-EOT
    The name of the first InfluxDB organization, which AWS creates with the instance, such as `engineering`. An organization is a workspace for a group of users; the admin user and `bucket` belong to it. 1 to 64 characters.

    AWS uses it only when it creates the instance, so the module ignores later changes to it (see `username`).
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = length(var.organization) >= 1 && length(var.organization) <= 64
    error_message = "organization must be 1 to 64 characters."
  }
}

variable "password" {
  description = <<-EOT
    The password of the InfluxDB admin user: 8 to 64 letters and digits; AWS refuses any other character. Without it, the module creates a 32-character password. Either way, the password is in the Terraform state, so protect the state.

    AWS stores the user name, password, organization and bucket in an AWS Secrets Manager secret that it creates in your account, whose ARN is in the `metadata` output at `timestreaminfluxdb_db_instance.influx_auth_parameters_secret_arn`. That secret is a copy: changing it does not change the password.

    AWS uses the password only when it creates the instance, so the module ignores later changes to it (see `username`). To change it, use the InfluxDB user interface or the `influx` CLI.
  EOT
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.password == null || can(regex("^[A-Za-z0-9]{8,64}$", coalesce(var.password, "-")))
    error_message = "password must be 8 to 64 letters and digits."
  }
}

variable "port" {
  description = <<-EOT
    The port InfluxDB listens on, from `1024` to `65535`, except `2375`, `2376`, `7788` to `7799`, `8090` and `51678` to `51680`, which AWS reserves. Without it, AWS uses `8086`. The security group allows this port. Changing it later is done in place and restarts the instance.
  EOT
  type        = number
  default     = null

  validation {
    condition = var.port == null || try(
      var.port >= 1024 && var.port <= 65535 && floor(var.port) == var.port &&
      !contains([2375, 2376, 7788, 7789, 7790, 7791, 7792, 7793, 7794, 7795, 7796, 7797, 7798, 7799, 8090, 51678, 51679, 51680], var.port),
      false
    )
    error_message = "port must be a whole number from 1024 to 65535, and not 2375, 2376, 7788 to 7799, 8090 or 51678 to 51680."
  }
}

variable "publicly_accessible" {
  description = <<-EOT
    Give the instance a public IP address, so its endpoint resolves to it from outside the VPC. Defaults to `false`. It also needs public subnets in `subnet_ids` and a `security_group_ingress` source outside the VPC. Keep databases private; reach them through the VPC instead. Changing it later replaces the instance and deletes its data.
  EOT
  type        = bool
  default     = false
  nullable    = false
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the instance and everything else in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.
  EOT
  type        = string
  default     = null
}

variable "security_group_ingress" {
  description = <<-EOT
    Who can reach InfluxDB over the network. The module creates a security group for the instance that allows the InfluxDB port (TCP) from each source listed here, and from nothing else. It allows no outbound traffic: the instance only answers connections, and security groups let replies out on their own. With the default, `{}`, no client can connect. The keys are names you choose; they only identify each rule, so a security group created in the same configuration can be used. Rules can be added and removed later without changing the instance.

    Each source takes exactly one of:

    - `cidr_ipv4` - An IPv4 range, such as `10.0.0.0/16`.
    - `cidr_ipv6` - An IPv6 range, such as `2600:1f18:1234:5600::/56`.
    - `security_group_id` - A security group whose members may connect, such as the group of your application servers.
    - `prefix_list_id` - A managed prefix list of ranges.

    and optionally:

    - `description` - (Optional) What the source is. Defaults to the key.
  EOT
  type = map(object({
    cidr_ipv4         = optional(string)
    cidr_ipv6         = optional(string)
    security_group_id = optional(string)
    prefix_list_id    = optional(string)
    description       = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for s in values(var.security_group_ingress) :
      length([for v in [s.cidr_ipv4, s.cidr_ipv6, s.security_group_id, s.prefix_list_id] : v if v != null]) == 1
    ])
    error_message = "Each security_group_ingress entry needs exactly one of cidr_ipv4, cidr_ipv6, security_group_id or prefix_list_id."
  }

  validation {
    condition = alltrue([
      for s in values(var.security_group_ingress) :
      (s.cidr_ipv4 == null || can(cidrnetmask(s.cidr_ipv4))) && (s.cidr_ipv6 == null || (can(cidrhost(s.cidr_ipv6, 0)) && strcontains(coalesce(s.cidr_ipv6, "-"), ":")))
    ])
    error_message = "security_group_ingress: cidr_ipv4 must be an IPv4 range such as 10.0.0.0/16, and cidr_ipv6 an IPv6 range such as 2600:1f18:1234:5600::/56."
  }
}

variable "storage" {
  description = <<-EOT
    The instance's storage. Every type includes its I/O operations per second (IOPS) in the price.

    - `type` - (Optional) `InfluxIOIncludedT1` (3,000 IOPS), the default, `InfluxIOIncludedT2` (12,000 IOPS) or `InfluxIOIncludedT3` (16,000 IOPS). `InfluxIOIncludedT2` and `InfluxIOIncludedT3` need at least 400 GiB.
    - `allocated` - (Optional) Size in GiB, up to `15360`. Defaults to `20`, the smallest AWS allows for `InfluxIOIncludedT1`. Storage can grow later in place, but never shrink, and after a change AWS refuses another for 6 hours.
  EOT
  type = object({
    type      = optional(string, "InfluxIOIncludedT1")
    allocated = optional(number, 20)
  })
  default  = {}
  nullable = false

  validation {
    condition     = contains(["InfluxIOIncludedT1", "InfluxIOIncludedT2", "InfluxIOIncludedT3"], var.storage.type)
    error_message = "storage.type must be InfluxIOIncludedT1, InfluxIOIncludedT2 or InfluxIOIncludedT3."
  }

  validation {
    condition     = try(var.storage.allocated >= 20 && var.storage.allocated <= 15360 && floor(var.storage.allocated) == var.storage.allocated, false)
    error_message = "storage.allocated must be a whole number of GiB from 20 to 15360."
  }

  validation {
    condition     = var.storage.type == "InfluxIOIncludedT1" || try(var.storage.allocated >= 400, false)
    error_message = "storage.allocated must be at least 400 GiB for InfluxIOIncludedT2 and InfluxIOIncludedT3."
  }
}

variable "subnet_ids" {
  description = <<-EOT
    The IDs of 1 to 3 subnets of `vpc_id` for the instance, such as `["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]`. Use private subnets; with `multi_az`, give subnets in at least two Availability Zones. AWS cannot move an instance to other subnets, so any change to this list replaces the instance and deletes its data.
  EOT
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(var.subnet_ids) >= 1 && length(var.subnet_ids) <= 3
    error_message = "subnet_ids must have 1 to 3 subnet IDs."
  }

  validation {
    condition     = alltrue([for id in var.subnet_ids : can(regex("^subnet-[a-z0-9]+$", id))])
    error_message = "Each entry in subnet_ids must be a subnet ID, such as subnet-0123456789abcdef0."
  }
}

variable "timeouts" {
  description = <<-EOT
    How long Terraform waits for the database instance.

    - `create` - (Optional) Defaults to `180m`. A new instance took 9 to 11 minutes in testing, with or without a Multi-AZ standby, but AWS creates only one instance at a time in each Region (see the README), so a create can wait for others.
    - `update` - (Optional) Defaults to `120m`.
    - `delete` - (Optional) Defaults to `120m`.
  EOT
  type = object({
    create = optional(string, "180m")
    update = optional(string, "120m")
    delete = optional(string, "120m")
  })
  default  = {}
  nullable = false
}

variable "username" {
  description = <<-EOT
    The name of the InfluxDB admin user, such as `admin`: a letter, then letters, digits and single hyphens, not ending with a hyphen; at most 64 characters. Defaults to `admin`. The password is in `password`.

    AWS uses `username`, `password`, `organization` and `bucket` only when it creates the instance, and could change them only by replacing it, which deletes its data. So the module ignores later changes to all four: a new value has no effect on an existing instance. Change them inside InfluxDB instead.
  EOT
  type        = string
  default     = "admin"
  nullable    = false

  validation {
    condition     = length(var.username) <= 64 && can(regex("^[A-Za-z]([A-Za-z0-9]*(-[A-Za-z0-9]+)*)?$", var.username))
    error_message = "username must start with a letter, contain only letters, digits and single hyphens, not end with a hyphen, and have at most 64 characters."
  }
}

variable "vpc_id" {
  description = <<-EOT
    The ID of the VPC the instance is in, such as `vpc-0123456789abcdef0`: the VPC of `subnet_ids`. The module creates the instance's security group in it.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a VPC ID, such as vpc-0123456789abcdef0."
  }
}
