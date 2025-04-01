resource "random_password" "this" {
  length      = 14
  special     = false
  min_upper   = 1
  min_numeric = 1
}
