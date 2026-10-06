# Complete

Most of the module's options together:

- A `db.influx.medium` instance, `example-complete`, with a standby in a second Availability Zone (Multi-AZ), which about doubles the cost.
- 50 GiB of storage with 3,000 IOPS included.
- The admin user `influxadmin`, with a password the module creates, the organization `example` and the bucket `metrics`.
- Access on port 8086 only from members of a security group the example creates for the clients. Attach that group to the instances or tasks that write and read metrics.
- The InfluxDB logs delivered to a private, encrypted S3 bucket, under `InfluxLogs/`; AWS documents hourly delivery. The bucket policy lets only the Timestream for InfluxDB service write there, under that prefix.
- An extra `CostCenter` tag on every resource.

## Run it

Choose a VPC and 2 or 3 private subnets in it, in different Availability Zones:

```shell
terraform init
terraform apply -var 'vpc_id=vpc-0123456789abcdef0' -var 'subnet_ids=["subnet-0123456789abcdef0","subnet-0fedcba9876543210"]'
```

Creating the instance takes about 10 minutes. The `influxdb` output gives its URL, the ARN of the secret with the admin user name and password, the clients' security group and the log bucket.

To remove it, run `terraform destroy` with the same `-var` options. The instance and its data are deleted, and so is the log bucket with the logs in it; remove `force_destroy` from the bucket to keep them.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

- <a name="requirement_random"></a> [random](#requirement_random) (~> 3.0)

### Required Inputs

The following input variables are required:

#### <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)

Description: IDs of 2 or 3 private subnets of the VPC, in different Availability Zones

Type: `list(string)`

#### <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)

Description: ID of the VPC to create the instance in

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_influxdb"></a> [influxdb](#output_influxdb)

Description: Where to connect, the ARN of the Secrets Manager secret that holds the admin user name and password, the clients' security group, and the log bucket
<!-- END_TF_DOCS -->
