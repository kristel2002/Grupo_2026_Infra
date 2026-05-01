variable "environment" {
  description = "Ambiente de trabajo (ej. dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegarán los Security Groups"
  type        = string
}

variable "vpc_cidr" {
  description = "Rango CIDR de la VPC para reglas de firewall interno"
  type        = string
}

variable "allowed_management_ips" {
  description = "Lista de IPs permitidas para administración"
  type        = list(string)
  default     = []
}

variable "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  type        = string
  default     = "seabook-cluster"
}