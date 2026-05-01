# 1. BLOQUE DE METADATOS
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 2. PROVEEDOR
provider "aws" {
  region  = var.aws_region
  profile = "default"
}

# 3. MÓDULO 1: NETWORKING
module "networking" {
  source = "./modules/networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  enable_nat_gateway   = var.enable_nat_gateway
}

# 4. MÓDULO 2: SEGURIDAD
module "security" {
  source = "./modules/security"

  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  vpc_cidr               = module.networking.vpc_cidr_block
  allowed_management_ips = var.allowed_management_ips
  ecs_cluster_name       = "seabook-cluster-${var.environment}"

  depends_on = [module.networking]
}

# 5. MÓDULO 3: COMPUTE
module "compute" {
  source = "./modules/compute"

  environment                 = var.environment
  vpc_id                      = module.networking.vpc_id
  public_subnet_ids           = module.networking.public_subnet_ids
  private_subnet_ids          = module.networking.private_subnet_ids
  alb_security_group_id       = module.security.alb_security_group_id
  ecs_security_group_id       = module.security.ecs_security_group_id
  ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.security.ecs_task_role_arn
  certificate_arn             = var.certificate_arn
  container_image             = var.container_image
  cpu_units                   = var.cpu_units
  memory_limit                = var.memory_limit
  desired_count               = var.desired_count
  max_capacity                = var.max_capacity
  min_capacity                = var.min_capacity

  depends_on = [module.security]
}

# 6. MÓDULO 4: DATABASE
module "database" {
  source = "./modules/database"

  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  availability_zones      = var.availability_zones
  private_subnet_ids      = module.networking.private_subnet_ids
  private_route_table_ids = module.networking.private_route_table_ids
  db_security_group_id    = module.security.db_security_group_id
  kms_key_arn             = module.security.kms_key_arn
  db_password             = var.db_password
  # db_name y db_master_username usan valores por defecto del módulo

  depends_on = [module.networking, module.security]
}

# 7. MÓDULO 5: CI/CD
module "cicd" {
  source = "./modules/cicd"

  environment             = var.environment
  ecr_repository_url      = var.ecr_repository_url
  sonar_host_url          = var.sonar_host_url
  sonar_token             = var.sonar_token
  codestar_connection_arn = var.codestar_connection_arn
  ecs_cluster_name        = try(module.compute.ecs_cluster_name, "seabook-cluster-${var.environment}")
  ecs_service_name        = try(module.compute.ecs_service_name, "user-service-${var.environment}")

  depends_on = [module.compute]
}