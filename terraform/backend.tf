terraform {
  backend "s3" {
    bucket         = "project-bedrock-tf-state-femisco"
    key            = "bedrock/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "project-bedrock-tf-lock"
    encrypt        = true
  }
}
