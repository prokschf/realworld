provider "aws" {
  region = "eu-central-1"

}

terraform {
  backend "s3" {
    bucket         = "realworld-state-terraform"
    key            = "init/deploy_infra/terraform.tfstate"
    region         = "eu-central-1"

    
    dynamodb_table = "realworld-lock-terraform"
    encrypt        = true
  }
}