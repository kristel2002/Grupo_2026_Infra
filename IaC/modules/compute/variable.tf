variable "environment" {
  description = "Entorno (dev, qa, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegará el clúster"
  type        = string
}

# --- RED ---
variable "private_subnet_ids" {
  description = "Subredes para los contenedores (Aislamiento RNF 18)"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Subredes para el ALB"
  type        = list(string)
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para alta disponibilidad"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# --- SEGURIDAD Y ROLES ---
variable "certificate_arn" {
  description = "ARN del certificado SSL/TLS en ACM"
  type        = string
  default     = ""
}

variable "alb_security_group_id" {
  description = "ID del security group para el ALB"
  type        = string
}

variable "ecs_security_group_id" {
  description = "ID del security group para las tareas ECS"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "Rol para que ECS descargue imágenes de ECR y escriba en CloudWatch"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "Rol para que el código de la App acceda a DynamoDB/S3"
  type        = string
}

# --- CONFIGURACIÓN DE LA APLICACIÓN ---
variable "container_image" {
  description = "Imagen del contenedor a desplegar"
  type        = string
  default     = "nginx:latest"  # Cambiar por tu imagen real
}

variable "container_port" {
  description = "Puerto del contenedor"
  type        = number
  default     = 80
}

variable "app_name" {
  description = "Nombre de la aplicación"
  type        = string
  default     = "seabook-user"
}

# --- VARIABLES DE ESCALABILIDAD (RNF 19) ---
variable "cpu_units" {
  description = "CPU para la tarea (ej. 256, 512, 1024) - Para 15,000 usuarios"
  type        = string
  default     = "512"  # Aumentado para mejor rendimiento
}

variable "memory_limit" {
  description = "Memoria para la tarea (ej. 512, 1024, 2048)"
  type        = string
  default     = "1024"  # Aumentado para mejor rendimiento
}

variable "desired_count" {
  description = "Número de instancias base del microservicio"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Capacidad máxima para soportar los 15,000 clics simultáneos (RNF 19)"
  type        = number
  default     = 10
}

variable "min_capacity" {
  description = "Capacidad mínima para mantener disponibilidad"
  type        = number
  default     = 2
}

# --- VARIABLES PARA BLUE/GREEN DEPLOYMENT (RNF 22) ---
variable "enable_blue_green" {
  description = "Habilitar despliegue Blue/Green para zero downtime"
  type        = bool
  default     = true
}

variable "deployment_controller_type" {
  description = "Tipo de controlador de despliegue (ECS o CODE_DEPLOY)"
  type        = string
  default     = "CODE_DEPLOY"
}

# --- VARIABLES DE AUTOSCALING ---
variable "cpu_target_value" {
  description = "Target de CPU para autoescalado (%)"
  type        = number
  default     = 70
}

variable "memory_target_value" {
  description = "Target de memoria para autoescalado (%)"
  type        = number
  default     = 70
}

variable "scale_in_cooldown" {
  description = "Tiempo de espera para scale in (segundos)"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Tiempo de espera para scale out (segundos)"
  type        = number
  default     = 60
}

# --- VARIABLES DE LOGS Y MONITOREO (RNF 21) ---
variable "enable_cloudwatch_logs" {
  description = "Habilitar logs en CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Días de retención de logs en CloudWatch"
  type        = number
  default     = 30
}

# --- VARIABLES DE HEALTH CHECK ---
variable "health_check_path" {
  description = "Ruta para health check del ALB"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Intervalo de health check (segundos)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout del health check (segundos)"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Umbral saludable para health check"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Umbral no saludable para health check"
  type        = number
  default     = 2
}