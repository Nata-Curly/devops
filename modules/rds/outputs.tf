output "instance_endpoint" {
  value       = try(aws_db_instance.this[0].address, null)
  description = "Endpoint for single RDS instance (null when Aurora is enabled)"
}

output "instance_port" {
  value       = try(aws_db_instance.this[0].port, null)
  description = "Port for single RDS instance (null when Aurora is enabled)"
}

output "cluster_endpoint" {
  value       = try(aws_rds_cluster.this[0].endpoint, null)
  description = "Cluster endpoint for Aurora (null when single instance is used)"
}

output "cluster_reader_endpoint" {
  value       = try(aws_rds_cluster.this[0].reader_endpoint, null)
  description = "Cluster reader endpoint for Aurora (null when single instance is used)"
}

output "cluster_port" {
  value       = try(aws_rds_cluster.this[0].port, null)
  description = "Port for Aurora cluster (null when single instance is used)"
}

output "security_group_id" {
  value = aws_security_group.db_sg.id
}
