output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app.id
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "application_url" {
  description = "URL of the petclinic application "
  value       = "http://${aws_instance.app.public_ip}:9090"
}

output "grafana_url" {
  description = "HTTP URL using the EC2 public ip and port 3000"
  value       = "http://${aws_instance.app.public_ip}:3000"
}

output "database_address" {
  description = "Used by the application as its PostgreSQL host"
  value       = aws_db_instance.postgres.address
}

output "database_port" {
  value = aws_db_instance.postgres.port
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}


