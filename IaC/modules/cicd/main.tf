# --- 1. S3 BUCKET PARA ARTEFACTOS ---
resource "aws_s3_bucket" "artifacts" {
  bucket        = "seabook-artifacts-${var.environment}"
  force_destroy = true
  
  tags = {
    Name        = "seabook-artifacts-${var.environment}"
    Environment = var.environment
  }
}

# Versión del bucket
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encriptación del bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- 2. IAM ROLES ---
resource "aws_iam_role" "pipeline_role" {
  name = "seabook-pipeline-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "seabook-pipeline-role-${var.environment}"
    Environment = var.environment
  }
}

# Política para CodePipeline
resource "aws_iam_role_policy" "pipeline_policy" {
  name = "seabook-pipeline-policy-${var.environment}"
  role = aws_iam_role.pipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:StopBuild"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# Política específica para CodeBuild (necesaria para logs)
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "seabook-codebuild-policy-${var.environment}"
  role = aws_iam_role.pipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- 3. CODEBUILD PARA DOCKER ---
resource "aws_codebuild_project" "app_build" {
  name          = "seabook-build-${var.environment}"
  description   = "Construcción de la imagen Docker para SeaBook"
  service_role  = aws_iam_role.pipeline_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    
    environment_variable {
      name  = "REPOSITORY_URI"
      value = var.ecr_repository_url
    }
    
    environment_variable {
      name  = "SONAR_HOST_URL"
      value = var.sonar_host_url != "" ? var.sonar_host_url : "https://sonarcloud.io"
    }

    environment_variable {
      name  = "SONAR_TOKEN"
      value = var.sonar_token != "" ? var.sonar_token : "dummy-token"
    }
    
    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = {
    Name        = "seabook-build-${var.environment}"
    Environment = var.environment
  }
}

# --- 4. PROYECTO CODEBUILD PARA CHECKOV ---
resource "aws_codebuild_project" "security_scan" {
  name          = "seabook-checkov-${var.environment}"
  description   = "Escaneo de seguridad con Checkov"
  service_role  = aws_iam_role.pipeline_role.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "bridgecrew/checkov:latest"
    type         = "LINUX_CONTAINER"
    
    environment_variable {
      name  = "CHECKOV_OUTPUT_FORMAT"
      value = "json"
    }
    
    environment_variable {
      name  = "CHECKOV_SKIP_CHECK"
      value = ""
    }
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = "checkov-buildspec.yml"
  }

  tags = {
    Name        = "seabook-checkov-${var.environment}"
    Environment = var.environment
  }
}

# --- 5. CODEPIPELINE CORREGIDO ---
resource "aws_codepipeline" "this" {
  name     = "seabook-pipeline-${var.environment}"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = "tu-organizacion/seabook-app"  # ⚠️ CAMBIA ESTO
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "SecurityScan"
    action {
      name             = "CheckovScan"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      configuration = {
        ProjectName = aws_codebuild_project.security_scan.name
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }
    }
  }

  #  STAGE DE DEPLOY CORREGIDO para ECS Blue/Green
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["build_output"]
      
      configuration = {
        ApplicationName                = "AppECS-${var.ecs_cluster_name}"
        DeploymentGroupName            = "DgpECS-${var.ecs_service_name}"
        TaskDefinitionTemplateArtifact = "build_output"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "build_output"
        AppSpecTemplatePath            = "appspec.yaml"
      }
    }
  }
  
  tags = {
    Name        = "seabook-pipeline-${var.environment}"
    Environment = var.environment
  }
}