module "prod" {
  source = "../../infra"

  repository_name = "production" # Always use lowercase letters, no special characters or numbers or it may not work properly.

  environment = "prod"

}