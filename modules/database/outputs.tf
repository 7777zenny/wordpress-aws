output "endpoint" {
  value = aws_db_instance.wordpress.endpoint
}

output "database_name" {
  value = aws_db_instance.wordpress.db_name
}

output "database_username" {
  value = aws_db_instance.wordpress.username
}