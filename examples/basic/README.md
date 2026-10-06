# Basic instance

A private Timestream for InfluxDB instance, `example-basic`, in the subnets you give. Anything in the VPC can reach it on port 8086. The module creates the admin user `admin` with a generated password, the organization `example` and the bucket `metrics`; AWS keeps a copy of them in AWS Secrets Manager.

Everything else uses the module's defaults: the smallest instance type, `db.influx.medium`, 20 GiB of storage with 3,000 IOPS included, one Availability Zone, and no logs.

## Run it

Choose a VPC and 1 to 3 private subnets in it:

```shell
terraform init
terraform apply -var 'vpc_id=vpc-0123456789abcdef0' -var 'subnet_ids=["subnet-0123456789abcdef0"]'
```

Creating the instance takes about 10 minutes. The `influxdb` output gives its URL and the ARN of the secret with the admin user name and password. Read the password from the secret, then sign in to the InfluxDB user interface at that URL from a machine in the VPC, or use the `influx` CLI:

```shell
aws secretsmanager get-secret-value --secret-id '<secret ARN>' --query SecretString --output text
```

To remove it, run `terraform destroy` with the same `-var` options. The instance and its data are deleted.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

- <a name="requirement_random"></a> [random](#requirement_random) (~> 3.0)

### Required Inputs

The following input variables are required:

#### <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)

Description: IDs of 1 to 3 private subnets of the VPC for the instance

Type: `list(string)`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of the VPC to create the instance in

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_influxdb"></a> [influxdb](#output_influxdb)

Description: Where to connect, and the ARN of the Secrets Manager secret that holds the admin user name and password
<!-- END_TF_DOCS -->
