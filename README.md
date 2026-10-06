# Terraform module for Amazon Timestream for InfluxDB

Creates an Amazon Timestream for InfluxDB database instance, which runs the InfluxDB 2 time series database, with a security group that controls which clients can reach it. AWS sets up the first admin user, organization and bucket when it creates the instance. Optional settings cover a standby in a second Availability Zone (Multi-AZ), storage, the port, IPv6, DB parameter groups and log delivery to Amazon S3.

The defaults are the settings most instances should have. An instance created with only the required inputs is private, encrypted, and cannot be reached over the network until you allow a source.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Encryption at rest | Always on, with a key AWS owns | None |
| Admin password | 32 letters and digits, created by the module; AWS keeps a copy in Secrets Manager | `password` |
| Admin user | `admin` | `username` |
| Network access | None: no client can connect | `security_group_ingress` |
| Outbound traffic | None | `additional_security_group_ids` |
| Public IP address | None | `publicly_accessible` |
| Port | `8086` | `port` |
| IP protocols | IPv4 | `network_type` |
| Storage | 20 GiB with 3,000 IOPS included (`InfluxIOIncludedT1`) | `storage` |
| Multi-AZ standby | Off | `multi_az` |
| Engine settings | InfluxDB defaults | `db_parameter_group_identifier` |
| Log delivery to S3 | Off | `log_delivery` |

## Usage

```hcl
module "influxdb" {
  source  = "AutomateTheCloud/influx/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Metrics"
    environment = "Production"
  }

  name             = "metrics-production"
  db_instance_type = "db.influx.medium"
  organization     = "engineering"
  bucket           = "metrics"
  vpc_id           = "vpc-0123456789abcdef0"
  subnet_ids       = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]

  security_group_ingress = {
    app = { security_group_id = "sg-0123456789abcdef0", description = "Application servers" }
  }
}
```

`details`, `name`, `db_instance_type`, `organization`, `bucket`, `vpc_id` and `subnet_ids` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on every resource.

Clients connect over HTTPS to `module.influxdb.metadata.timestreaminfluxdb_db_instance.endpoint` on `module.influxdb.metadata.timestreaminfluxdb_db_instance.port`. The admin user name and password are in the Secrets Manager secret at `module.influxdb.metadata.timestreaminfluxdb_db_instance.influx_auth_parameters_secret_arn`.

The module uses your default `aws` provider and creates everything in that provider's Region. To create the instance somewhere else without configuring another provider, set `region`:

```hcl
module "influxdb_us_west_2" {
  source  = "AutomateTheCloud/influx/aws"
  version = "~> 1.0"

  region           = "us-west-2"
  details          = { scope = "Automate the Cloud", purpose = "Metrics", environment = "Production" }
  name             = "metrics-production"
  db_instance_type = "db.influx.medium"
  organization     = "engineering"
  bucket           = "metrics"
  vpc_id           = "vpc-0abcdef0123456789"
  subnet_ids       = ["subnet-0abcdef0123456789"]
}
```

The VPC and subnets must be in that Region too.

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the instance belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Metrics"            # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at an instance in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the instance, its network and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Metrics"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "metrics" {
  source  = "AutomateTheCloud/influx/aws"
  version = "~> 1.0"

  details          = local.details
  name             = "metrics-production"
  db_instance_type = "db.influx.medium"
  organization     = "engineering"
  bucket           = "metrics"
  vpc_id           = "vpc-0123456789abcdef0"
  subnet_ids       = ["subnet-0123456789abcdef0"]
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.metrics.metadata.timestreaminfluxdb_db_instance.endpoint` for the host name clients connect to, or `module.metrics.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`, given a VPC and private subnets.

- [Basic instance](https://github.com/AutomateTheCloud/terraform-aws-influx/tree/main/examples/basic): a private instance that anything in the VPC can reach.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-influx/tree/main/examples/complete): most of the module's options, with a Multi-AZ standby, access from one security group, and the logs delivered to an S3 bucket.

## Things to know

### Settings that replace the instance

AWS can change only an instance's type, storage, Multi-AZ standby, port, parameter group and log delivery. Everything else is fixed when it is created, and a change replaces the instance, which **deletes its data**:

- `name`, `subnet_ids`, `vpc_id`, `publicly_accessible` and `network_type`;
- `additional_security_group_ids`: AWS cannot change an instance's security groups;
- removing `db_parameter_group_identifier` (setting or changing it is done in place).

The module's own security group never changes in a way that replaces it: its name and description depend only on `name`, and `details` reach it only through its tags. Its rules can be added and removed at any time.

Before applying, read the plan: `must be replaced` on `aws_timestreaminfluxdb_db_instance.this` means the data will be deleted. To keep the data, back it up first; see [Backup and restore](https://docs.aws.amazon.com/timestream/latest/developerguide/influxdb2-customer-managed-backup-restore.html) in the AWS documentation.

### The admin user, password, organization and bucket

AWS uses `username`, `password`, `organization` and `bucket` only to set up InfluxDB when it creates the instance, and could change them only by replacing it. So the module ignores later changes to all four: a new value has no effect. Change the password, and add users, organizations and buckets, inside InfluxDB, with its user interface or the [`influx` CLI](https://docs.influxdata.com/influxdb/v2/tools/influx-cli/).

Without `password`, the module creates a 32-character password of letters and digits, the only characters AWS accepts. Either way, the password is in the Terraform state, so keep the state in an encrypted backend that only administrators can read. AWS also stores the four values in a Secrets Manager secret it creates in your account, at `metadata.timestreaminfluxdb_db_instance.influx_auth_parameters_secret_arn`:

```shell
aws secretsmanager get-secret-value --secret-id '<secret ARN>' --query SecretString --output text
```

That secret is a read-only copy of the values AWS used at creation: changing the password in InfluxDB does not update it, and changing the secret does not change the password. AWS deletes the secret, at once, when it deletes the instance.

For applications, create an API token in InfluxDB with only the permissions they need, rather than using the admin user; see [How Timestream for InfluxDB uses secrets](https://docs.aws.amazon.com/timestream/latest/developerguide/timestream-for-influx-security-db-secrets.html).

### Creating instances

A new instance took 9 to 11 minutes in testing, with or without a Multi-AZ standby. AWS creates only one instance at a time in each account and Region: while one is being created, it refuses another with `ThrottlingException`, and the AWS provider retries until the first is done. Two instances in one apply, or in two configurations at once, therefore take about twice as long, and the second shows `Still creating...` while it waits.

The instance's `availability_zone` and `secondary_availability_zone`, in `metadata`, are the zone names AWS reports, which can differ from the names of the same zones in your account. An instance in subnets in `us-east-1a` and `us-east-1b` was reported in `us-east-1d` and `us-east-1c`; its network interfaces were in the subnets given.

### Network access

The module's security group allows the InfluxDB port, over TCP, from the sources in `security_group_ingress`, and nothing else. It has no outbound rules: the instance only answers connections, and security groups let replies out on their own.

Keep the instance private. `publicly_accessible = true` gives it a public IP address, but it is reachable only from sources in `security_group_ingress`, and only in public subnets.

### Changing an instance

The instance type, storage, Multi-AZ standby, port and log delivery change in place. In testing each change took between 2 and 16 minutes; [AWS documents](https://docs.aws.amazon.com/timestream/latest/developerguide/timestream-for-influx-managing-modifying-db.html) that such changes restart InfluxDB and can cause an outage. Three things to expect, all seen in AWS:

- **One change at a time.** For a few minutes after a change finishes, while the instance already shows `AVAILABLE`, AWS refuses the next one with `ValidationException: ... has an update action ... in progress`. Nothing is changed; run `terraform apply` again a few minutes later.
- **Storage waits 6 hours.** After a storage change, AWS refuses another for 6 hours (`wait 6 hours before updating the storage again`). Storage can only grow (AWS documentation); `InfluxIOIncludedT2` and `InfluxIOIncludedT3` need at least 400 GiB.
- **A Multi-AZ instance fails over.** Changing the instance type of an instance with a standby swaps the primary and standby Availability Zones. AWS provider 6.67.0 does not expect that, and the apply ends with `Provider produced inconsistent result after apply` for `availability_zone`. The change is made, Terraform saves it, and the next plan shows no changes.

### Log delivery

With `log_delivery`, AWS writes the InfluxDB engine logs to the bucket under `InfluxLogs/<name>/<instance ID>/`, hourly according to [the AWS documentation](https://docs.aws.amazon.com/timestream/latest/developerguide/timestream-for-influx-managing-view-influx-logs.html). The bucket must be in the instance's account and Region, and its bucket policy must let the service write there; the [complete example](https://github.com/AutomateTheCloud/terraform-aws-influx/tree/main/examples/complete) shows it. AWS checks the policy when it creates the instance: a policy whose statement also required `aws:SourceAccount` made the create fail with `has invalid bucket policy`. To stop delivery, set `log_delivery.enabled = false` and apply, and keep the block. Removing `log_delivery` after it has been set makes the apply fail with `At least one updatable parameter must be set`: the AWS provider sends an update with nothing in it.

### InfluxDB 3 and read replicas

This module creates single InfluxDB 2 instances, with an optional Multi-AZ standby. InfluxDB 3 and InfluxDB 2 read replicas run as Timestream for InfluxDB clusters, which the module does not create.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-influx/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-influx/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

- <a name="requirement_random"></a> [random](#requirement_random) (>= 3.0)

### Required Inputs

The following input variables are required:

#### <a name="input_bucket"></a> [bucket](#input_bucket)

Description: The name of the first InfluxDB bucket, which AWS creates in `organization` with the instance, such as `metrics`. A bucket holds time series data and how long to keep it. 2 to 64 characters, not starting with an underscore, with no double quotes. Create more buckets inside InfluxDB.

AWS uses it only when it creates the instance, so the module ignores later changes to it (see `username`).

Type: `string`

#### <a name="input_db_instance_type"></a> [db_instance_type](#input_db_instance_type)

Description: The instance type, which sets the CPU and memory: `db.influx.medium`, `db.influx.large`, `db.influx.xlarge`, `db.influx.2xlarge`, `db.influx.4xlarge`, `db.influx.8xlarge`, `db.influx.12xlarge`, `db.influx.16xlarge` or `db.influx.24xlarge`. `db.influx.medium` is the smallest. `db.influx.24xlarge` needs AWS provider 6.5.0 or later; older versions refuse it at plan. Changing it later resizes the instance in place; see the README for what to expect with `multi_az`.

Type: `string`

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-influx#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_name"></a> [name](#input_name)

Description: The name of the database instance, such as `metrics-production`: 3 to 40 letters, digits and hyphens, starting with a letter, with no two hyphens in a row and no hyphen at the end. It must be unique among the account's instances in the Region, and starts the instance's endpoint address. The security group is named `influxdb-<name>`.

Changing it later replaces the instance and deletes its data.

Type: `string`

#### <a name="input_organization"></a> [organization](#input_organization)

Description: The name of the first InfluxDB organization, which AWS creates with the instance, such as `engineering`. An organization is a workspace for a group of users; the admin user and `bucket` belong to it. 1 to 64 characters.

AWS uses it only when it creates the instance, so the module ignores later changes to it (see `username`).

Type: `string`

#### <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)

Description: The IDs of 1 to 3 subnets of `vpc_id` for the instance, such as `["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]`. Use private subnets; with `multi_az`, give subnets in at least two Availability Zones. AWS cannot move an instance to other subnets, so any change to this list replaces the instance and deletes its data.

Type: `list(string)`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: The ID of the VPC the instance is in, such as `vpc-0123456789abcdef0`: the VPC of `subnet_ids`. The module creates the instance's security group in it.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_additional_security_group_ids"></a> [additional_security_group_ids](#input_additional_security_group_ids)

Description: More security groups to attach to the database instance, beside the one the module creates, such as `["sg-0123456789abcdef0"]`. At most 4: AWS allows 5 per instance. Choose them before you create the instance: AWS cannot change an instance's security groups, so any change to this list replaces the instance and deletes its data.

Type: `list(string)`

Default: `[]`

#### <a name="input_db_parameter_group_identifier"></a> [db_parameter_group_identifier](#input_db_parameter_group_identifier)

Description: The ID of a DB parameter group with InfluxDB engine settings, such as the log level or query limits. The AWS provider has no resource for these groups; create one with the AWS CLI (`aws timestream-influxdb create-db-parameter-group`) or the console. AWS cannot delete a parameter group once it exists. Without it, InfluxDB uses its default settings.

Setting or changing it later is done in place and restarts the instance. Removing it replaces the instance and deletes its data.

Type: `string`

Default: `null`

#### <a name="input_log_delivery"></a> [log_delivery](#input_log_delivery)

Description: Send the InfluxDB engine logs to an Amazon S3 bucket, under the `InfluxLogs/` prefix; AWS documents hourly delivery. The bucket must be in the same account and Region as the instance, and its bucket policy must let the `timestream-influxdb.amazonaws.com` service principal call `s3:PutObject` on `<bucket ARN>/InfluxLogs/*`. AWS checks the policy when it creates the instance, and refused one whose statement also required `aws:SourceAccount`; [`examples/complete`](https://github.com/AutomateTheCloud/terraform-aws-influx/tree/main/examples/complete) shows one. With the default, `null`, no logs are delivered.

- `s3_bucket_name` - (Required) The name of the bucket.
- `enabled` - (Optional) Deliver logs. Defaults to `true`. To stop delivery, set it to `false` and apply, and keep `log_delivery`: removing it after it has been set makes the apply fail (`At least one updatable parameter must be set`).

Type:

```hcl
object({
    s3_bucket_name = string
    enabled        = optional(bool, true)
  })
```

Default: `null`

#### <a name="input_multi_az"></a> [multi_az](#input_multi_az)

Description: Keep a standby instance in another Availability Zone, which AWS fails over to when the primary or its zone fails. It needs `subnet_ids` in at least two Availability Zones, and about doubles the cost. Defaults to `false`. Turning it on or off later is done in place.

Type: `bool`

Default: `false`

#### <a name="input_network_type"></a> [network_type](#input_network_type)

Description: The IP protocols clients can use to reach the instance: `IPV4`, or `DUAL` for IPv4 and IPv6. `DUAL` needs subnets with IPv6 ranges. Without it, AWS uses `IPV4`. Changing it later replaces the instance and deletes its data.

Type: `string`

Default: `null`

#### <a name="input_password"></a> [password](#input_password)

Description: The password of the InfluxDB admin user: 8 to 64 letters and digits; AWS refuses any other character. Without it, the module creates a 32-character password. Either way, the password is in the Terraform state, so protect the state.

AWS stores the user name, password, organization and bucket in an AWS Secrets Manager secret that it creates in your account, whose ARN is in the `metadata` output at `timestreaminfluxdb_db_instance.influx_auth_parameters_secret_arn`. That secret is a copy: changing it does not change the password.

AWS uses the password only when it creates the instance, so the module ignores later changes to it (see `username`). To change it, use the InfluxDB user interface or the `influx` CLI.

Type: `string`

Default: `null`

#### <a name="input_port"></a> [port](#input_port)

Description: The port InfluxDB listens on, from `1024` to `65535`, except `2375`, `2376`, `7788` to `7799`, `8090` and `51678` to `51680`, which AWS reserves. Without it, AWS uses `8086`. The security group allows this port. Changing it later is done in place and restarts the instance.

Type: `number`

Default: `null`

#### <a name="input_publicly_accessible"></a> [publicly_accessible](#input_publicly_accessible)

Description: Give the instance a public IP address, so its endpoint resolves to it from outside the VPC. Defaults to `false`. It also needs public subnets in `subnet_ids` and a `security_group_ingress` source outside the VPC. Keep databases private; reach them through the VPC instead. Changing it later replaces the instance and deletes its data.

Type: `bool`

Default: `false`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the instance and everything else in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.

Type: `string`

Default: `null`

#### <a name="input_security_group_ingress"></a> [security_group_ingress](#input_security_group_ingress)

Description: Who can reach InfluxDB over the network. The module creates a security group for the instance that allows the InfluxDB port (TCP) from each source listed here, and from nothing else. It allows no outbound traffic: the instance only answers connections, and security groups let replies out on their own. With the default, `{}`, no client can connect. The keys are names you choose; they only identify each rule, so a security group created in the same configuration can be used. Rules can be added and removed later without changing the instance.

Each source takes exactly one of:

- `cidr_ipv4` - An IPv4 range, such as `10.0.0.0/16`.
- `cidr_ipv6` - An IPv6 range, such as `2600:1f18:1234:5600::/56`.
- `security_group_id` - A security group whose members may connect, such as the group of your application servers.
- `prefix_list_id` - A managed prefix list of ranges.

and optionally:

- `description` - (Optional) What the source is. Defaults to the key.

Type:

```hcl
map(object({
    cidr_ipv4         = optional(string)
    cidr_ipv6         = optional(string)
    security_group_id = optional(string)
    prefix_list_id    = optional(string)
    description       = optional(string)
  }))
```

Default: `{}`

#### <a name="input_storage"></a> [storage](#input_storage)

Description: The instance's storage. Every type includes its I/O operations per second (IOPS) in the price.

- `type` - (Optional) `InfluxIOIncludedT1` (3,000 IOPS), the default, `InfluxIOIncludedT2` (12,000 IOPS) or `InfluxIOIncludedT3` (16,000 IOPS). `InfluxIOIncludedT2` and `InfluxIOIncludedT3` need at least 400 GiB.
- `allocated` - (Optional) Size in GiB, up to `15360`. Defaults to `20`, the smallest AWS allows for `InfluxIOIncludedT1`. Storage can grow later in place, but never shrink, and after a change AWS refuses another for 6 hours.

Type:

```hcl
object({
    type      = optional(string, "InfluxIOIncludedT1")
    allocated = optional(number, 20)
  })
```

Default: `{}`

#### <a name="input_timeouts"></a> [timeouts](#input_timeouts)

Description: How long Terraform waits for the database instance.

- `create` - (Optional) Defaults to `180m`. A new instance took 9 to 11 minutes in testing, with or without a Multi-AZ standby, but AWS creates only one instance at a time in each Region (see the README), so a create can wait for others.
- `update` - (Optional) Defaults to `120m`.
- `delete` - (Optional) Defaults to `120m`.

Type:

```hcl
object({
    create = optional(string, "180m")
    update = optional(string, "120m")
    delete = optional(string, "120m")
  })
```

Default: `{}`

#### <a name="input_username"></a> [username](#input_username)

Description: The name of the InfluxDB admin user, such as `admin`: a letter, then letters, digits and single hyphens, not ending with a hyphen; at most 64 characters. Defaults to `admin`. The password is in `password`.

AWS uses `username`, `password`, `organization` and `bucket` only when it creates the instance, and could change them only by replacing it, which deletes its data. So the module ignores later changes to all four: a new value has no effect on an existing instance. Change them inside InfluxDB instead.

Type: `string`

Default: `"admin"`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
- `timestreaminfluxdb_db_instance` - The database instance: its `endpoint` (the host name clients connect to, over HTTPS), `port`, `arn`, `id`, `influx_auth_parameters_secret_arn` (the AWS Secrets Manager secret that AWS created with the admin user name and password), and the rest of its attributes. The password is left out. `availability_zone` and `secondary_availability_zone` are the names AWS reports, which can differ from the names of the same zones in your account: an instance in subnets in `us-east-1a` and `us-east-1b` was reported in `us-east-1d` and `us-east-1c`. `vpc_subnet_ids` shows where it really is.
- `security_group` - The instance's security group, with its `id`, `arn` and `name`.
- `vpc_security_group_ingress_rule` - The ingress rules, keyed like `security_group_ingress`, or `null` when there are none.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-influx/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-influx/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
