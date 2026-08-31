variable "aws_region" {
  type        = string
  description = "AWS region for Terraform state backend resources"
  default     = "ap-south-1"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "8byte-devops-assignment"
}