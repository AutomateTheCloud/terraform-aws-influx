# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  # The name and Name tag of the security group.
  security_group_name = "influxdb-${var.name}"

  # The port InfluxDB listens on: var.port, or the AWS default. Known from the inputs,
  # so the ingress rules never wait for the instance.
  port = coalesce(var.port, 8086)

  # Whether a password was given. Comparing a sensitive value gives a sensitive result,
  # which count cannot use; only this yes or no is made non-sensitive, not the password.
  password_given = nonsensitive(var.password != null)
}
