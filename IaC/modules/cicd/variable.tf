# --- 1. VARIABLES GENERALES ---
variable "aws_region" { 
  description = "Región de AWS para el despliegue"
  type        = string
  default     = "us-east-1" 
}

variable "environment" { 
  description = "Entorno de ejecución (dev/prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Nombre del proyecto UTP"
  type        = string
  default     = "SeaBook"
}

# --- 2. VARIABLES DE NETWORKING (RNF 18) ---
variable "vpc_cidr" { 
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16" 
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para alta disponibilidad (Multi-AZ)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"] 
}

variable "public_subnets_cidr" {
  description = "CIDR blocks para subredes públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets_cidr" {
  description = "CIDR blocks para subredes privadas"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" { 
  description = "Habilitar salida a internet para subredes privadas"
  type        = bool
  default     = true 
}

# --- 3. VARIABLES PARA EL MÓDULO CICD (AGREGADAS) ---
variable "ecr_repository_url" {
  description = "URL del repositorio ECR"
  type        = string
}

variable "sonar_host_url" {
  description = "URL del servidor SonarQube"
  type        = string
  default     = ""
}

variable "sonar_token" {
  description = "Token de SonarQube"
  type        = string
  sensitive   = true
  default     = ""
}

variable "codestar_connection_arn" {
  description = "ARN de la conexión CodeStar para GitHub"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  type        = string
}

variable "ecs_service_name" {
  description = "Nombre del servicio ECS a desplegar"
  type        = string
}