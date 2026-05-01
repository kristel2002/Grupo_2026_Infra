variable "environment" {
  description = "Ambiente (dev/prod) para el etiquetado de recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "Rango de IPs para la VPC (ej. 10.0.0.0/16)"
  type        = string
}

variable "availability_zones" {
  description = "Lista de zonas (mínimo 2 para cumplir con el RNF 17 de Disponibilidad)"
  type        = list(string)
}

variable "public_subnets_cidr" {
  description = "Rangos CIDR para las subredes del Load Balancer"
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "Rangos CIDR para las subredes de App y DB (Aislamiento RNF 18)"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Habilitar salida a internet para parches de seguridad (RNF 24)"
  type        = bool
  default     = true
}