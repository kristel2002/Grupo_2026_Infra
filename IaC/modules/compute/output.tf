# --- 1. CLUSTER Y SERVICIOS ---
output "ecs_cluster_name" {
  description = "Nombre del clúster ECS para SeaBook"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_id" {
  description = "ID del clúster (útil para políticas de IAM)"
  value       = aws_ecs_cluster.main.id
}

# Salidas necesarias para el módulo CICD (Agregadas)
output "ecs_cluster_arn" {
  description = "ARN del cluster ECS"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_names" {
  value = {
    user       = aws_ecs_service.user.name
    user_blue  = aws_ecs_service.user_blue.name
    user_green = aws_ecs_service.user_green.name
  }
}

# --- 2. RED Y BALANCEO ---
output "alb_dns_name" {
  description = "URL pública para acceder a SeaBook"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_listener_arn" {
  description = "ARN del listener donde CodeDeploy inyectará el tráfico Green"
  value       = aws_lb_listener.http.arn
}

output "alb_zone_id" {
  description = "ID de zona del ALB (necesario si vas a usar Route 53 con un dominio)"
  value       = aws_lb.main.zone_id
}

# --- 3. TARGET GROUPS (Para CI/CD Blue/Green RNF 22) ---
output "target_group_names" {
  description = "Nombres de los TGs para configurar el AppSpec de CodeDeploy"
  value = {
    user_blue  = aws_lb_target_group.blue.name
    user_green = aws_lb_target_group.green.name
  }
}

# --- 4. OBSERVABILIDAD (RNF 21) ---
output "log_group_user_service" {
  description = "Ruta de logs en CloudWatch para auditoría"
  value       = "/ecs/seabook-user-${var.environment}"
}