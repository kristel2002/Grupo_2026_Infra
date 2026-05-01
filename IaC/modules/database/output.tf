# --- 1. AURORA SERVERLESS V2 ---
output "aurora_cluster_id" {
  description = "ID del clúster Aurora Serverless v2"
  value       = aws_rds_cluster.aurora_serverless.id
}

output "aurora_cluster_arn" {
  description = "ARN del clúster Aurora para políticas de IAM"
  value       = aws_rds_cluster.aurora_serverless.arn
}

output "aurora_cluster_endpoint" {
  description = "Endpoint de conexión para la base de datos Aurora (escritura/lectura)"
  value       = aws_rds_cluster.aurora_serverless.endpoint
}

output "aurora_cluster_reader_endpoint" {
  description = "Endpoint de solo lectura para balanceo de cargas de consultas"
  value       = aws_rds_cluster.aurora_serverless.reader_endpoint
}

output "aurora_cluster_port" {
  description = "Puerto de conexión para la base de datos Aurora"
  value       = aws_rds_cluster.aurora_serverless.port
}

output "aurora_cluster_database_name" {
  description = "Nombre de la base de datos por defecto"
  value       = aws_rds_cluster.aurora_serverless.database_name
}

output "aurora_cluster_master_username" {
  description = "Usuario maestro de la base de datos"
  value       = aws_rds_cluster.aurora_serverless.master_username
  sensitive   = true
}

# --- 2. ALMACENAMIENTO PESADO (S3 - RNF 100TB) ---
output "s3_bucket_id" {
  description = "Nombre del bucket para PDFs de tesis y fotos"
  value       = aws_s3_bucket.data_storage.id
}

output "s3_bucket_arn" {
  description = "ARN del bucket para permisos de IAM"
  value       = aws_s3_bucket.data_storage.arn
}

output "s3_bucket_regional_domain_name" {
  description = "Nombre de dominio regional del bucket S3"
  value       = aws_s3_bucket.data_storage.bucket_regional_domain_name
}

# --- 3. VPC ENDPOINTS ---
output "rds_vpc_endpoint_id" {
  description = "ID del VPC Endpoint para RDS"
  value       = aws_vpc_endpoint.rds.id
}

output "rds_vpc_endpoint_dns" {
  description = "DNS del VPC Endpoint para RDS"
  value       = aws_vpc_endpoint.rds.dns_entry[0].dns_name
}

output "s3_vpc_endpoint_id" {
  description = "ID del VPC Endpoint para S3"
  value       = aws_vpc_endpoint.s3.id
}

# --- 4. INFORMACIÓN DE CONEXIÓN COMPLETA ---
output "aurora_connection_string" {
  description = "String de conexión completa para la aplicación"
  value       = "mysql://${aws_rds_cluster.aurora_serverless.master_username}:${var.db_password}@${aws_rds_cluster.aurora_serverless.endpoint}:${aws_rds_cluster.aurora_serverless.port}/${aws_rds_cluster.aurora_serverless.database_name}"
  sensitive   = true
}

output "aurora_reader_connection_string" {
  description = "String de conexión para lecturas (replicas)"
  value       = "mysql://${aws_rds_cluster.aurora_serverless.master_username}:${var.db_password}@${aws_rds_cluster.aurora_serverless.reader_endpoint}:${aws_rds_cluster.aurora_serverless.port}/${aws_rds_cluster.aurora_serverless.database_name}"
  sensitive   = true
}