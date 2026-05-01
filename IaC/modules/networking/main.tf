# --- 1. VPC ---
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "vpc-${var.environment}"
    Environment = var.environment
  }
}

# --- 2. INTERNET GATEWAY (Para salida a Internet de la capa pública) ---
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "igw-${var.environment}"
  }
}

# --- 3. SUBREDES PÚBLICAS (Para el Load Balancer) ---
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets_cidr)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "subnet-public-${count.index + 1}-${var.environment}"
    Environment = var.environment
  }
}

# --- 4. SUBREDES PRIVADAS (Para Microservicios y Base de Datos) ---
resource "aws_subnet" "private" {
  count             = length(var.private_subnets_cidr)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets_cidr[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "subnet-private-${count.index + 1}-${var.environment}"
    Environment = var.environment
  }
}

# --- 5. TABLA DE RUTEO PÚBLICA ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "rt-public-${var.environment}"
  }
}

# --- 6. ASOCIACIÓN DE RUTAS PÚBLICAS ---
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- 7. NAT GATEWAY (Para que la App descargue parches - RNF 24) ---
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id 

  tags = {
    Name = "nat-gw-${var.environment}"
  }
}

# --- 8. TABLA DE RUTEO PRIVADA (Salida vía NAT Gateway) ---
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }

  tags = {
    Name = "rt-private-${var.environment}"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- 9. SECURITY GROUPS (RNF 20 - Seguridad Transversal) ---

# Security Group para el Load Balancer (Acceso desde Internet)

resource "aws_security_group" "alb" {
  name        = "seabook-alb-sg-${var.environment}"
  vpc_id      = aws_vpc.this.id
  description = "Acceso publico al ALB"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Regla para HTTPS (RNF 20)
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group para los Microservicios (Aislamiento RNF 18)
resource "aws_security_group" "ecs" {
  name        = "seabook-ecs-sg-${var.environment}"
  vpc_id      = aws_vpc.this.id
  description = "Solo permite trafico desde el ALB"

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}