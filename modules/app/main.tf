
resource "random_password" "password" {
  length  = 16
  special = false
}

locals {
  db_identifier = format("%s-%s-%s", var.environment, var.app_name, "postgres")
}

//creating a route 53 for the database
resource "aws_route53_record" "postgress_cname" {
  zone_id = var.public_zone_id
  name    = format("%s.%s.%s", "postgresql", var.environment, var.public_domain_name)
  type    = "CNAME"
  ttl     = "5"
  records = [module.db.this_db_instance_address]
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = local.db_identifier

  engine         = "postgres"
  engine_version = "9.6"
  instance_class = "db.t2.large"

  allocated_storage = var.dbSize
  storage_encrypted = false

  //we might want to put a key here thus using the same password everytime?
  # kms_key_id        = "arm:aws:kms:<region>:<account id>:key/<kms key id>"
  name = var.app_name

  username               = var.db_username
  password               = random_password.password.result
  port                   = "5432"
  vpc_security_group_ids = var.security_group_id

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period         = var.backup_retention_period
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  subnet_ids                      = var.subnet_ids

  family               = "postgres9.6"
  major_engine_version = "9.6"

  final_snapshot_identifier = var.app_name
  deletion_protection       = var.protect_db_deletion

  tags = {
    Environment = var.environment
  }
}

