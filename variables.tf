variable "bucket" {
  description = "Bucket"
  type        = string
  default     = null
}

variable "credentials" {
  description = "Credentials"
  type        = any
  default     = null
}

variable "db_instance_type" {
  description = "Database Instance Type"
  type        = string
  default     = null
}

variable "db_parameter_group_identifier" {
  description = "Database Parameter Group Identifier"
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Enable MultiAZ"
  type        = bool
  default     = false
}

variable "name" {
  description = "Name"
  type        = string
  default     = null
}

variable "organization" {
  description = "Organization"
  type        = string
  default     = null
}

variable "publicly_accessible" {
  description = "Publicly Accessible"
  type        = bool
  default     = false
}

variable "security_groups_additional" {
  description = "Security Groups (Additional)"
  type        = list(any)
  default     = []
}

variable "security_group_additional_tags" {
  description = "Security Group - Additional Tags"
  type        = map(any)
  default     = {}
}

variable "security_group_rules" {
  description = "Security Group Rules"
  type        = any
  default     = null
}

variable "storage_size" {
  description = "Storage Size"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage Type"
  type        = string
  default     = "InfluxIOIncludedT1"
}

variable "subnets_tag" {
  description = "Subnets Tag"
  type        = string
  default     = null
}

variable "subnets" {
  description = "Subnets"
  type        = list(any)
  default     = []
}

variable "timeouts" {
  description = "Timeouts"
  type        = any
  default = {
    create = "180m"
    delete = "120m"
    update = "120m"
  }
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}
