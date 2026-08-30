resource "aws_db_instance" "postgres" {

  identifier                 = "rds-${var.project_name}-${var.environment}-postgres"
  db_name                    = var.db_name
  engine                     = "postgres"
  engine_version             = "17"
  instance_class             = "db.t4g.micro"
  storage_type               = "gp3"
  username                   = var.db_username
  password                   = var.db_password
  allocated_storage          = 20
  parameter_group_name       = "default.postgres17"
  skip_final_snapshot        = true
  db_subnet_group_name       = aws_db_subnet_group.database.name
  vpc_security_group_ids     = [aws_security_group.db.id]
  port                       = 5432
  storage_encrypted          = true
  publicly_accessible        = false
  multi_az                   = false
  apply_immediately          = true
  deletion_protection        = false
  delete_automated_backups   = true
  backup_retention_period    = 7
  auto_minor_version_upgrade = true
  tags = {
    Name = "rds-${var.project_name}-${var.environment}-postgres"
  }
}


resource "aws_db_subnet_group" "database" {
  name       = "rds-${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "rds-${var.project_name}-${var.environment}-db-subnet-group"
  }
}