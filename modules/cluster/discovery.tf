/**
 create the namespace and the discovery service
**/
resource "aws_service_discovery_private_dns_namespace" "discovery_namespace" {
  name        = var.environment
  description = format("%s %s %s", "A private discovery service for application ", var.environment , "ECS environment")
  vpc         = var.vpc_id
}
