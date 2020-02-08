provider "aws" {
  region = var.region
}

/**
  Create The Network Topology
  This should take care of the VPC, Subnets, Elastic IP's, Load Balancers....
**/
module "network" {
  source = "./modules/network"

  vpc_cidr             = var.vpc_cidr
  app_name             = var.app_name
  environment          = var.environment
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  ssl_certificate_arn  = var.ssl_certificate_arn
  single_nat_gateway   = var.single_nat_gateway
}

/**
  since i have a route 53 Manually created
  and pointing to xxx.com
  i will simply create a public CNAME on the public zone
  and attach it on to the Load Balancer
**/
resource "aws_route53_record" "env_alias" {
  zone_id = var.public_zone_id
  name    = format("%s.%s", var.environment, var.public_domain_name)
  type    = "A"

  alias {
    name                   = module.network.zone_name
    zone_id                = module.network.zone_id
    evaluate_target_health = false
  }
}

/**
  create The Elastic Container Cluster
**/
module "cluster" {
  source            = "./modules/cluster"
  name              = format("%s-%s", var.app_name, var.environment)
  environment       = var.environment
  min_size          = var.min_size
  max_size          = var.max_size
  desired_capacity  = var.desired_capacity
  instance_type     = var.instance_type
  ecs_aws_ami       = var.ecs_aws_ami
  vpc_id            = module.network.vpc_id
  cloudwatch_prefix = var.environment
  sg_alb_id         = module.network.sg_alb_id //accept only from this sg
  key_pair_name     = var.key_pair_name
  vpc_subnets       = module.network.private_subnets_ids
  bastion_sg_id     = module.jumpbox.bastion_sg_id //only accept connections from the bastion
}

/**
  a bastion which will be hosted on the private subnets
  and load balanced 
  and is able to be accessed using bastion-{}.xxx.com port 22
**/
module "jumpbox" {
  source             = "./modules/bastion"
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  public_subnets_ids = module.network.public_subnets_ids
  public_zone_id     = var.public_zone_id
  key_name           = var.key_pair_name
  private_subnet_ids = module.network.private_subnets_ids
  public_domain_name = var.public_domain_name
}

/**i
  create the application s3 buckets, database ...
**/
module "app" {
  source                   = "./modules/app"
  region                   = var.region
  app_name                 = var.app_name
  environment              = var.environment
  subnet_ids               = module.network.private_subnets_ids
  security_group_id        = [module.cluster.network_security_id]
  protect_db_deletion      = false
  dbSize                   = 50
  backup_retention_period  = 0
  public_zone_id           = var.public_zone_id
  cluster_id               = module.cluster.cluster_id
  target_group_arns        = module.network.target_group_arns
  public_domain_name       = var.public_domain_name
  db_username              = var.db_username
  ecs_service_discovery_id = module.cluster.ecs_service_discovery_id
}
