
variable "vpc_cidr" {}

variable single_nat_gateway {
  default = false
}


variable "environment" {}
variable "max_size" {}
variable "min_size" {}
variable "desired_capacity" {}
variable "instance_type" {}
variable "ecs_aws_ami" {}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "region" {}
variable "app_name" {}
variable "key_pair_name" {}

variable ssl_certificate_arn {}

variable "public_zone_id" {

}

variable "private_zone_id" {

}

variable "public_domain_name" {
  description = "The public domain name for the services that will be attached to the ALB"
  default     = ""
  type        = string
}

variable "db_username" {
  description = "The database user admin which will admin the database"
  default     = "db_admin"
  type        = string
}