variable "aws_region" {
  type        = string
  description = "AWS region of application infra"
  default     = "ap-south-1"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "8byte-devops-assignment"
}

variable "environment" {
  type        = string
  description = "8byte devops assignment environment"
  default     = "staging"
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR allowed to access application Grafana"
}

variable "db_name" {
  type    = string
  default = "petclinic"
}

variable "db_username" {
  type        = string
  description = "Username for the database"
  default     = "petclinicadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}
