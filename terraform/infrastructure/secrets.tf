resource "aws_secretsmanager_secret" "app_env" {
  name        = "${var.project_name}/${var.environment}/app-env"
  description = "Runtime environment values used by the Petclinic container"

  # This is a demo environment, so the secret can be deleted immediately
  # when the Terraform stack is destroyed.
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-${var.environment}-app-env"
  }
}
