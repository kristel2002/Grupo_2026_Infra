# --- 1. BASE DE DATOS RELACIONAL (AURORA SERVERLESS V2) ---
# Diseñado para soportar de 2TB a 100TB de data relacional

# Subnet group para Aurora
resource "aws_db_subnet_group" "aurora" {
  name       = "seabook-aurora-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids
  
  tags = {
    Name        = "seabook-aurora-subnet-group"
    Environment = var.environment
  }
}

# Parámetro de cluster para Aurora Serverless v2
resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = "seabook-aurora-params-${var.environment}"
  family      = "aurora-mysql8.0"
  description = "Parameter group for SeaBook Aurora Serverless v2"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
}

# Clúster Aurora Serverless v2
resource "aws_rds_cluster" "aurora_serverless" {
  cluster_identifier = "seabook-aurora-${var.environment}"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.02.0"
  engine_mode        = "provisioned"
  
  database_name      = "seabookdb"
  master_username    = "admin"
  master_password    = var.db_password # Variable sensible que debes definir
  
  vpc_security_group_ids = [var.db_security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name
  
  # Configuración Serverless v2
  serverlessv2_scaling_configuration {
    min_capacity = 0.5  # Mínima capacidad en ACU (0.5 ACU)
    max_capacity = 128  # Máxima capacidad para picos de 15,000 usuarios
  }
  
  # Alta disponibilidad Multi-AZ
  availability_zones = var.availability_zones
  
  # Backups y recuperación (RNF 15)
  backup_retention_period = 35
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"
  
  # Cifrado en reposo (RNF 20)
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn
  
  # Protección contra eliminación en producción
  deletion_protection = var.environment == "prod" ? true : false
  
  # Skip final snapshot para desarrollo, pero no para producción
  skip_final_snapshot = var.environment != "prod"
  
  tags = {
    Name        = "seabook-aurora-cluster"
    Environment = var.environment
  }
}

# Instancias de Aurora Serverless v2 (mínimo 2 para alta disponibilidad)
resource "aws_rds_cluster_instance" "aurora_instance" {
  count              = 2 # Dos instancias para alta disponibilidad Multi-AZ
  identifier         = "seabook-aurora-instance-${count.index + 1}-${var.environment}"
  cluster_identifier = aws_rds_cluster.aurora_serverless.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_serverless.engine
  engine_version     = aws_rds_cluster.aurora_serverless.engine_version
  
  # Promoción automática para mantener disponibilidad
  auto_minor_version_upgrade = true
  promotion_tier             = count.index + 1
  
  tags = {
    Name        = "seabook-aurora-instance-${count.index + 1}"
    Environment = var.environment
  }
}

# --- 2. ALMACENAMIENTO DE ARCHIVOS PESADOS (S3) ---
# Requerimiento: Hasta 100 TB de fotos y PDFs de tesis
resource "aws_s3_bucket" "data_storage" {
  bucket = "seabook-media-storage-${var.environment}"
  
  # Evita el borrado accidental de documentos de tesis
  lifecycle {
    prevent_destroy = true
  }
}

# Versionado para cumplir con el RNF de Recuperabilidad
resource "aws_s3_bucket_versioning" "storage_versioning" {
  bucket = aws_s3_bucket.data_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Regla de ciclo de vida para optimizar costos (100 TB es mucha data)
resource "aws_s3_bucket_lifecycle_configuration" "storage_lifecycle" {
  bucket = aws_s3_bucket.data_storage.id

  rule {
    id     = "archive-old-files"
    status = "Enabled"

    # SOLUCIÓN AL WARNING: Se añade un filtro vacío para aplicar a todo el bucket
    filter {}

    transition {
      days          = 90
      storage_class = "GLACIER" # Mueve tesis antiguas a almacenamiento barato
    }
  }
}

# --- 3. SEGURIDAD: VPC ENDPOINTS (Página 20 del PDF) ---
# VPC Endpoint para Aurora (conexión privada)
resource "aws_vpc_endpoint" "rds" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.us-east-1.rds"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.db_security_group_id]
  private_dns_enabled = true
  
  tags = {
    Name        = "seabook-rds-endpoint-${var.environment}"
    Environment = var.environment
  }
}

# VPC Endpoint para S3 (acceso privado a los 100TB de archivos)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids
  
  tags = {
    Name        = "seabook-s3-endpoint-${var.environment}"
    Environment = var.environment
  }
}