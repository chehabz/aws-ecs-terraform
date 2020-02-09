variable "region" {}
variable "app_name" {}
variable "environment" {}

variable "security_group_id" {
  description = "The security group where the database will resides."
}

variable "protect_db_deletion" {
  default     = 0
  description = "Whether we would like to back up the database or not"
}

variable "dbSize" {
  description = "In GiB the storage size of the database"
}

variable "subnet_ids" {
  type = list(string)
}

variable "backup_retention_period" {

}

variable public_zone_id {

}

variable "cluster_id" {
  description = "the cluster that the service will run on"
  default = ""
  type = string
}

variable "public_domain_name" {
  description = "the public domain name which I use in my route 53"
  default = ""
  type = string
}

variable "target_group_arns"{
  description = "ALB target groups"
  default = []
  type = list(string)
}

variable "db_username" {
  description = "the database admin"
  default = ""
  type = string
}

variable "ecs_service_discovery_id"{
  description = "The service discovery service"
  default = ""
  type = string
}