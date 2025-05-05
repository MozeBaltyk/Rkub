## ensure computer_name meets 15 character limit
## uses assumption that resources only use 4 characters for a suffix

locals {
  computer_name_prefix = substr(var.prefix, 0, 11)
}