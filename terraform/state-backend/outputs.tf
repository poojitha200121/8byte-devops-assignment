output "state_bucket_name" {
  description = "Name of s3 bucket name used for terraform state bucket name"
  value       = aws_s3_bucket.terraform_state.id
}