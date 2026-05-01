# --- ACCESO A LA APLICACIÓN ---
output "alb_dns_name" {
  description = "URL pública para acceder al portal de SeaBook"
  value       = module.compute.alb_dns_name
}

# --- INFORMACIÓN DE RED ---
output "vpc_id" {
  description = "ID de la red principal Multi-AZ"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  value       = module.networking.private_subnet_ids
}

# --- INFORMACIÓN DE COMPUTO ---
output "ecs_cluster_name" {
  description = "Nombre del clúster ECS"
  value       = module.compute.ecs_cluster_name
}

output "ecs_cluster_id" {
  description = "ID del clúster ECS"
  value       = module.compute.ecs_cluster_id
}

output "ecs_cluster_arn" {
  description = "ARN del cluster ECS"
  value       = module.compute.ecs_cluster_arn
}

output "ecs_service_names" {
  description = "Nombres de los servicios ECS desplegados"
  value       = module.compute.ecs_service_names
}

output "alb_listener_arn" {
  description = "ARN del listener del ALB"
  value       = module.compute.alb_listener_arn
}

output "target_group_names" {
  description = "Nombres de los Target Groups (Blue/Green)"
  value       = module.compute.target_group_names
}

# --- ALMACENAMIENTO Y BASE DE DATOS ---
output "aurora_cluster_endpoint" {
  description = "Endpoint de conexión para la base de datos Aurora"
  value       = module.database.aurora_cluster_endpoint
}

output "s3_bucket_media_id" {
  description = "Nombre del bucket S3 para almacenamiento"
  value       = module.database.s3_bucket_id
}

# --- PIPELINE DE CI/CD ---
output "codepipeline_id" {
  description = "ID del pipeline de CI/CD"
  value       = module.cicd.codepipeline_id
}

output "codepipeline_arn" {
  description = "ARN del pipeline de CI/CD"
  value       = module.cicd.codepipeline_arn
}

# --- SEGURIDAD ---
output "kms_key_arn" {
  description = "ARN de la llave KMS que cifra los datos"
  value       = module.security.kms_key_arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN del rol de ejecución de ECS"
  value       = module.security.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN del rol de tarea de ECS"
  value       = module.security.ecs_task_role_arn
}

# --- ESTADO DEL SISTEMA ---
output "deployment_status" {
  description = "Estado del despliegue de SeaBook"
  value       = "Infraestructura de SeaBook desplegada exitosamente"
}