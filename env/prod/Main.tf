module "prod" {
  source = "../../infra"

  repository_name = "production" # Always use lowercase letters, no special characters or numbers or it may not work properly.

  environment = "prod"

  IAMRole = "prod" # After creating the variable, use the name of the variable in this field. This will create an AWS IAM role with that specific name and attach it to the ECS service.

}