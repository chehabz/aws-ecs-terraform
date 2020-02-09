variable "additional_user_data_script" {
  description = "Additional user data script (default=\"\")"
  default     = ""
}

variable "vpc_subnets" {}
variable "environment" {}
variable "max_size" {}
variable "min_size" {}
variable "desired_capacity" {}
variable "instance_type" {}
variable "ecs_aws_ami" {}
variable "name" {}
variable "key_pair_name" {}

variable "vpc_id" {}

variable "cloudwatch_prefix" {}

variable "sg_alb_id" {}

variable bastion_sg_id {}