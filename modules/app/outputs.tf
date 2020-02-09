output "db_password" {
  value = random_password.password.result
}

output "db_endpoint" {
  value = module.db.this_db_instance_address
}
