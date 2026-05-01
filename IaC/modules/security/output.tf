output "alb_security_group_id" {
  description = "ID del SG del Load Balancer"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID del SG de los Microservicios"
  value       = aws_security_group.ecs.id
}

output "db_security_group_id" {
  description = "ID del SG de Aurora"
  value       = aws_security_group.db.id
}

output "ecs_task_execution_role_arn" {
  description = "ARN del rol de ejecución de ECS"
  value       = aws_iam_role.ecs_exec_role.arn
}

output "ecs_task_execution_role_name" {
  description = "Nombre del rol de ejecución de ECS"
  value       = aws_iam_role.ecs_exec_role.name
}

output "ecs_task_role_arn" {
  description = "ARN del rol de tarea de ECS"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_task_role_name" {
  description = "Nombre del rol de tarea de ECS"
  value       = aws_iam_role.ecs_task_role.name
}

output "kms_key_arn" {
  description = "ARN de la llave KMS"
  value       = aws_kms_key.seabook_data.arn 
}

output "kms_key_id" {
  description = "ID de la llave KMS"
  value       = aws_kms_key.seabook_data.key_id
}

output "kms_key_alias" {
  description = "Alias de la llave KMS"
  value       = aws_kms_alias.seabook_data.name
}