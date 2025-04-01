terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: InfluxDB
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

  publicly_accessible = false
  vpc_id = "vpc-00000000000000001"

  timeouts = {
    create = "180m"
    delete = "120m"
    update = "120m"
  }
}

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value = module.influxdb.metadata
}
