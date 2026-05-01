# 1. ID DE LA VPC
output "vpc_id" {
  description = "El ID de la VPC para SeaBook"
  value       = aws_vpc.this.id 
}

output "vpc_cidr_block" {
  description = "El CIDR block de la VPC para reglas de firewall"
  value       = aws_vpc.this.cidr_block
}

# 2. SUBREDES (Públicas para ALB, Privadas para App/DB)
output "private_subnet_ids" {
  description = "Lista de IDs de las subredes privadas (RNF 18)"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas"
  value       = aws_subnet.public[*].id
}

# 3. SECURITY GROUPS (RNF 20 - Seguridad por Capas)
output "alb_security_group_id" {
  description = "ID del SG del Balanceador de Carga"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID del SG de los Microservicios"
  value       = aws_security_group.ecs.id
}

# 4. RUTEO (Para VPC Endpoints de DynamoDB/S3 - Página 20 del PDF)
output "private_route_table_ids" {
  description = "IDs de las tablas de ruteo privadas"
  value       = [aws_route_table.private.id]
}