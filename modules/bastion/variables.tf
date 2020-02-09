variable "environment" {}
variable "vpc_id" {}

variable "public_subnets_ids" {
  type = list(string)
}

variable "public_zone_id" {

}

variable "key_name" {

}

variable private_subnet_ids {
  type = list(string)
}

variable "public_domain_name" {
  description = "the public domain name which I use in my route 53"
  default = ""
  type = string
}