variable "environment" {
  description = "Ambiente de trabajo (dev/prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC para configurar los Endpoints de Aurora y S3 (RNF 18)"
  type        = string
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para alta disponibilidad de Aurora (Multi-AZ)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Subredes privadas para aislamiento de datos"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "IDs de las tablas de ruteo privadas para asociar los VPC Endpoints"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Grupo de seguridad que permite tráfico desde microservicios a Aurora"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN de la llave KMS para cifrado de 100TB de datos en Aurora y S3"
  type        = string
}

variable "db_password" {
  description = "Contraseña para la base de datos Aurora Serverless v2"
  type        = string
  sensitive   = true
}

# --- VARIABLES DE CONFIGURACIÓN DE BASE DE DATOS (AGREGADAS) ---
variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "seabookdb"
}

variable "db_master_username" {
  description = "Usuario maestro"
  type        = string
  default     = "admin"
}

# --- VARIABLES OPCIONALES ADICIONALES (RECOMENDADAS) ---
variable "db_port" {
  description = "Puerto de la base de datos Aurora"
  type        = number
  default     = 3306
}

variable "db_backup_retention_period" {
  description = "Período de retención de backups en días"
  type        = number
  default     = 35
}

variable "db_preferred_backup_window" {
  description = "Ventana preferida para backups (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "db_preferred_maintenance_window" {
  description = "Ventana preferida para mantenimiento (UTC)"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "db_deletion_protection" {
  description = "Proteger la base de datos contra eliminación accidental"
  type        = bool
  default     = true
}

variable "db_auto_pause" {
  description = "Pausa automática para Aurora Serverless v2 (true/false)"
  type        = bool
  default     = true
}

variable "db_seconds_until_auto_pause" {
  description = "Segundos de inactividad antes de pausar Aurora Serverless"
  type        = number
  default     = 300
}

variable "db_min_capacity" {
  description = "Capacidad mínima de Aurora Serverless v2 (ACU)"
  type        = number
  default     = 0.5
}

variable "db_max_capacity" {
  description = "Capacidad máxima de Aurora Serverless v2 (ACU) para 100TB de datos"
  type        = number
  default     = 128
}

variable "engine_version" {
  description = "Versión de Aurora MySQL"
  type        = string
  default     = "8.0.mysql_aurora.3.05.2"
}