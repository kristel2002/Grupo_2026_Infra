output "codepipeline_arn" {
  description = "ARN del pipeline de CI/CD"
  value       = aws_codepipeline.this.arn
}

output "codepipeline_id" {
  description = "ID del pipeline"
  value       = aws_codepipeline.this.id
}

output "artifact_bucket_name" {
  description = "Nombre del bucket de artefactos"
  value       = aws_s3_bucket.artifacts.id
}

output "codebuild_project_name" {
  description = "Nombre del proyecto de CodeBuild"
  value       = aws_codebuild_project.app_build.name
}