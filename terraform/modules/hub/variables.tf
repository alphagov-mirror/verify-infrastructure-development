variable "deployment" {
  description = "Name of the deployment; {joint,staging,prod,integration}"
}

variable "tools_account_id" {
  description = "AWS account id of the tools account, where docker images will be pulled from"
}

variable "number_of_prometheus_apps" {
  default = 1
}

variable "publically_accessible_from_cidrs" {
  type = "list"
}

variable "mgmt_accessible_from_cidrs" {
  type = "list"
}

locals {
  root_domain                  = replace(var.signin_domain, "/www[.]/", "")
  number_of_availability_zones = 1
}

variable "wildcard_cert_arn" {
  default = "ACM cert arn for wildcard of signin_domain"
}

variable "instance_type" {
  default = "t2.micro"
}