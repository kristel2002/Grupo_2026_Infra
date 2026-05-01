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

# --- 2. VARIABLES DE NETWORKING ---
variable "vpc_cidr" { 
  description = "CIDR block para la VPC"
  type        = string
  default     = "10.0.0.0/16" 
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para alta disponibilidad"
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

# --- 3. VARIABLES DE SEGURIDAD ---
variable "allowed_management_ips" {
  description = "IPs autorizadas para administración"
  type        = list(string)
  default     = ["190.0.0.1/32"]
}

variable "certificate_arn" {
  description = "ARN del certificado SSL en ACM para HTTPS"
  type        = string
  default     = ""
}

# --- 4. VARIABLES DE COMPUTE ---
variable "container_image" {
  description = "Imagen del contenedor a desplegar"
  type        = string
  default     = "nginx:latest"
}

variable "cpu_units" {
  description = "CPU para la tarea (256, 512, 1024)"
  type        = string
  default     = "512"
}

variable "memory_limit" {
  description = "Memoria para la tarea (512, 1024, 2048)"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Número de instancias base del microservicio"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Capacidad máxima para autoescalado"
  type        = number
  default     = 10
}

variable "min_capacity" {
  description = "Capacidad mínima para autoescalado"
  type        = number
  default     = 2
}

# --- 5. VARIABLES DE BASE DE DATOS ---
variable "db_password" {
  description = "Contraseña para la base de datos Aurora"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "seabookdb"
}

variable "db_master_username" {
  description = "Usuario maestro para Aurora"
  type        = string
  default     = "admin"
}

# --- 6. VARIABLES PARA CICD ---
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
  description = "Token de autenticación para SonarQube"
  type        = string
  sensitive   = true
  default     = ""
}

variable "codestar_connection_arn" {
  description = "ARN de la conexión CodeStar para GitHub"
  type        = string
}