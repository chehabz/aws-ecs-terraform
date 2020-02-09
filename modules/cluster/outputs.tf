output "cluster_id" {
  value = aws_ecs_cluster.ecs.id
}

output "network_security_id" {
  value = aws_security_group.instance_sg.id
}

output "ecs_service_discovery_id" {
  description = "provides a discovery mechanism for containers"
  value = aws_service_discovery_private_dns_namespace.discovery_namespace.id
}
