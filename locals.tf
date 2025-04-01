locals {
  database_password = try(var.credentials.password, null) != null ? var.credentials.password : random_password.this.result

  subnets = try(var.subnets_tag, "") != "" ? distinct(compact(concat(tolist(data.aws_subnets.this[0].ids), try(var.subnets, [])))) : try(var.subnets, null)
}
