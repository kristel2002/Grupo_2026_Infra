# --- 1. ECS CLUSTER ---
resource "aws_ecs_cluster" "main" {
  name = "seabook-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# --- 2. APPLICATION LOAD BALANCER (ALB) ---
resource "aws_lb" "main" {
  name               = "seabook-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  
  tags = {
    Name        = "seabook-alb-${var.environment}"
    Environment = var.environment
  }
}

# --- 3. TARGET GROUPS (Blue y Green para despliegues seguros) ---
# Mejora RNF 17: Optimización de tiempos para soportar 15,000 usuarios
resource "aws_lb_target_group" "blue" {
  name        = "tg-user-blue-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  deregistration_delay = 30 # Reduce el tiempo de espera al drenar conexiones

  health_check {
    path                = "/health"
    interval            = 15  # Más frecuente para detectar fallas rápido
    timeout             = 5
    healthy_threshold   = 2   # Acelera el marcado como sano para escalado rápido
    unhealthy_threshold = 3
    matcher             = "200"
  }
  
  tags = {
    Name        = "tg-user-blue-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "green" {
  name        = "tg-user-green-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  deregistration_delay = 30 

  health_check {
    path                = "/health"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
  
  tags = {
    Name        = "tg-user-green-${var.environment}"
    Environment = var.environment
  }
}

# --- 4. ALB LISTENER ---
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
  
  tags = {
    Name        = "seabook-listener-${var.environment}"
    Environment = var.environment
  }
}

# ✅ AGREGADO: Listener para HTTPS si hay certificate_arn
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
  
  tags = {
    Name        = "seabook-listener-https-${var.environment}"
    Environment = var.environment
  }
}

# ✅ AGREGADO: Servicio ECS Blue para despliegues Blue/Green
resource "aws_ecs_service" "user_blue" {
  name            = "user-service-blue-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "user-app"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }
  
  depends_on = [aws_lb_listener.http]
  
  tags = {
    Name        = "user-service-blue-${var.environment}"
    Environment = var.environment
  }
}

# ✅ AGREGADO: Servicio ECS Green para despliegues Blue/Green
resource "aws_ecs_service" "user_green" {
  name            = "user-service-green-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = "user-app"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }
  
  depends_on = [aws_lb_listener.http]
  
  tags = {
    Name        = "user-service-green-${var.environment}"
    Environment = var.environment
  }
}

# --- 5. TASK DEFINITION (Mejorada con Logs para RNF 21) ---
resource "aws_ecs_task_definition" "user" {
  family                   = "user-task-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu_units
  memory                   = var.memory_limit
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "user-app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      
      # Configuración de logs para auditoría y trazabilidad
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.user_log_group.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
      
      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "SERVICE_NAME"
          value = "user-service"
        }
      ]
    }
  ])
  
  tags = {
    Name        = "user-task-${var.environment}"
    Environment = var.environment
  }
}

# --- 6. AUTO SCALING (RNF 19: Escalabilidad Automática) ---
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.user_blue.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_value
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# ✅ AGREGADO: Política de autoescalado basada en memoria
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_target_value
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# --- 7. LOG GROUP (Necesario para la Task Definition) ---
resource "aws_cloudwatch_log_group" "user_log_group" {
  name              = "/ecs/seabook-user-${var.environment}"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name        = "/ecs/seabook-user-${var.environment}"
    Environment = var.environment
  }
}

# AGREGADO: Data source para región actual
data "aws_region" "current" {}