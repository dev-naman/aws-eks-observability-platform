terraform {

  backend "s3" {

    bucket         = "naman-jain-devops-terraform-state-2026"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"

    encrypt = true
  }
}