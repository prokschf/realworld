To Create Terraform Lock and state run:

terraform/init/state_lock/terraform init
terraform/init/state_lock/terraform apply -var-file=../default.init.tfvars


To Create ECR and IAM roles for deployment

terraform/init/deploy_infra/terraform init
terraform/init/deploy_infra/terraform apply -var-file=../default.init.tfvars
