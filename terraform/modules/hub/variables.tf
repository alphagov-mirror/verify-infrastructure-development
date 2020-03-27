variable "deployment" {
  description = "Name of the deployment; {development,staging,prod,integration}"
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
  number_of_availability_zones = 1
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ecs_agent_image_digest" {}
variable "nginx_image_digest" {}
variable "prometheus_image_digest" {}
