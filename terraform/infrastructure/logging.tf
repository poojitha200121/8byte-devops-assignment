resource "aws_cloudwatch_log_group" "application" {

  name              = "${var.project_name}-${var.environment}-application-logs"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-application-logs"
  }

}