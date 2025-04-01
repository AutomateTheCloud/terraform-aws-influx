# AWS - InfluxDB - Terraform Module
Terraform module for creating AWS Timestream InfluxDB databases (AutomateTheCloud model)

***

## Usage
```hcl
module "influxdb" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope               = "Demo"
    purpose             = "InfluxDB"
    environment         = "np"
    additional_tags = {
      "Project"         = "Project Name"
      "ProjectID"       = "123456789"
      "Contact"         = "David Singer - david.singer@example.com"
    }
  }

  name = "influxdb-test-np"
  
  db_instance_type = "db.influx.large"
  
  storage_type = "InfluxIOIncludedT1"
  storage_size = 20

  bucket       = "warehouse"
  organization = "udw"

  credentials = {
    username = "admin"
  }

  subnets_tag = "restricted"
  
  # db_parameter_group_identifier = "blah blah"

  security_group_rules = [
    # {
      # source      = "sg-00000000000000001"
      # description = "Security Group Test"
    # },
    {
      source      = "10.0.0.0/8"
      description = "CIDR Test"
    }
  ]

  # security_group_additional_tags = {
    # "TestAddition" = "it works"
  # }

  vpc_id = "vpc-00000000000000001"

  timeouts = {
    create = "180m"
    delete = "120m"
    update = "120m"
  }
}
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `bucket` | Bucket | `string` | |
| `credentials` | Credentials | `any` | |
| `db_instance_type` | Database Instance Type | `string` | |
| `db_parameter_group_identifier` | Database Parameter Group Identifier | `string` | |
| `multi_az` | Enable MultiAZ | `bool` | `false` |
| `name` | Name | `string` | |
| `organization` | Organization | `string` | |
| `publicly_accessible` | Publicly Accessible | `bool` | `false` |
| `security_groups_additional` | Security Groups (Additional) | `list(any)` | `[]` |
| `security_group_additional_tags` | Security Group - Additional Tags | `map` | `{}` |
| `security_group_rules` | Security Group Rules (TODO - Info) | `any` | |
| `storage_size` | Storage Size | `number` | `100` |
| `storage_type` | Storage Type | `string` | `InfluxIOIncludedT1` |
| `subnets_tag` | Subnets Tag | `string` | |
| `subnets` | Subnets | `list(any)` | `{}` |
| `timeouts` | Timeouts (TODO - Info) | `any` | |
| `vpc_id` | VPC ID | `string` | |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object serve? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `appautoscaling.target` | Application Autoscaling - Target |
| `appautoscaling.policy.scale_on_cpu` | Application Autoscaling - Policy - Scale on CPU |
| `appautoscaling.policy.scale_on_connection_count` | Application Autoscaling - Policy - Scale on Connection Count |
| `cloudwatch.log_group` | Cloudwatch - LogGroup |
| `iam.role.rds_enhanced_monitoring` | IAM - Role: RDS Enhanced Monitoring |
| `rds.cluster` | RDS: Cluster |
| `rds.cluster_instance` | RDS: Cluster Instance |
| `security_group` | Security Group |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
