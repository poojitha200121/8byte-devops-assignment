resource "aws_secretsmanager_secret" "app_env" {
  name        = "${var.project_name}/${var.environment}/app-env"
  description = "Runtime environment values used by the Petclinic container"

  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-${var.environment}-app-env"
  }
}
