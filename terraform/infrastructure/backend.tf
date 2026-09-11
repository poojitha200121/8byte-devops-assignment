terraform {
  backend "s3" {
    bucket       = "8byte-devops-assignment-terraform-state-521223133967"
    key          = "staging/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
