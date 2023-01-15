provider "aws" {
  region = "eu-central-1"

}

terraform {
  backend "s3" {
    bucket = "realworld-state-terraform"
    key    = "staging/backend/terraform.tfstate"
    region = "eu-central-1"


    dynamodb_table = "realworld-lock-terraform"
    encrypt        = true
  }
}


module "backend" {
  source       = "../../modules/backend"
  stage_name   = "staging"
  project_name = "realworld"
  VPC_cidr     = "10.40.0.0/16"
}

