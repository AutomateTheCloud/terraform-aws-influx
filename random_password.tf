# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The admin password, when none is given. AWS accepts only letters and digits, from 8 to
# 64 of them. The result is in the Terraform state.
resource "random_password" "this" {
  count = local.password_given ? 0 : 1

  length      = 32
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}
