resource "aws_security_group" "app" {

  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "security group for ${var.project_name} application and monitoring"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-app-sg"
  }

}

resource "aws_security_group" "db" {

  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "security group for ${var.project_name} database"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-db-sg"
  }

}


resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.app.id

  cidr_ipv4   = var.allowed_cidr
  from_port   = 9090
  ip_protocol = "tcp"
  to_port     = 9090
}


resource "aws_vpc_security_group_ingress_rule" "grafana_http" {
  security_group_id = aws_security_group.app.id

  cidr_ipv4   = var.allowed_cidr
  from_port   = 3000
  ip_protocol = "tcp"
  to_port     = 3000
}

resource "aws_vpc_security_group_egress_rule" "app_http" {
  security_group_id = aws_security_group.app.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}


resource "aws_vpc_security_group_ingress_rule" "postgres_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}