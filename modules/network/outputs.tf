output "vpc_id" {
  value = module.vpc.vpc_id
}

output "zone_id" {
  value = module.alb.this_lb_zone_id
}

output "zone_name" {
  value = module.alb.this_lb_dns_name
}

output "target_group_arns" {
  value = module.alb.target_group_arns
}

output "public_subnets_ids" {
  value = module.vpc.public_subnets
}

output "private_subnets_ids" {
  value = module.vpc.private_subnets
}

output "sg_alb_id" {
  value = aws_security_group.alb.id
}
