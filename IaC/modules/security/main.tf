# --- SECURITY GROUP: LOAD BALANCER ---
resource "aws_security_group" "alb" {
  name        = "seabook-alb-sg-${var.environment}"
  description = "Permite trafico HTTP y HTTPS desde internet"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "seabook-alb-sg-${var.environment}"
    Environment = var.environment
  }
}

# --- SECURITY GROUP: ECS ---
resource "aws_security_group" "ecs" {
  name        = "seabook-ecs-sg-${var.environment}"
  description = "Permite trafico solo desde el ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "seabook-ecs-sg-${var.environment}"
    Environment = var.environment
  }
}

# --- SECURITY GROUP: DATABASE (AURORA) ---
resource "aws_security_group" "db" {
  name        = "seabook-db-sg-${var.environment}"
  description = "Permite trafico de la App hacia Aurora"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "seabook-db-sg-${var.environment}"
    Environment = var.environment
  }
}

# --- ROLES IAM PARA ECS ---
resource "aws_iam_role" "ecs_exec_role" {
  name = "seabook-ecs-exec-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "seabook-ecs-exec-role-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "seabook-ecs-task-role-${var.environment}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "seabook-ecs-task-role-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "ecs_app_permissions" {
  name = "seabook-app-policy-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "rds-db:connect",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Effect   = "Allow"
        Resource = "*" 
      },
      {
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject"]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::seabook-media-${var.environment}",
          "arn:aws:s3:::seabook-media-${var.environment}/*"
        ]
      },
      {
        Action   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
        Effect   = "Allow"
        Resource = aws_kms_key.seabook_data.arn
      }
    ]
  })
}

# --- KMS ---
resource "aws_kms_key" "seabook_data" {
  description             = "Llave para cifrar datos sensibles de SeaBook"
  deletion_window_in_days = 7
  enable_key_rotation     = true 

  tags = {
    Name        = "seabook-kms-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "seabook_data" {
  name          = "alias/seabook-kms-${var.environment}"
  target_key_id = aws_kms_key.seabook_data.key_id
}