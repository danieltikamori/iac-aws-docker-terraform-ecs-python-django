module "prod" {
  source = "../../infra"

  repository_name = "production" # Always use lowercase letters, no special characters or numbers or it may not work properly.

  environment = "prod"

  IAMRole = "prod" # After creating the variable, use the name of the variable in this field. This will create an AWS IAM role with that specific name and attach it to the ECS service.

}

output "DNS_alb" {
  value = module.prod.DNS # Outputs the DNS address to make easier to get the Load Balancer DNS. This is useful when you need to add it manually in your /etc/hosts file for example.
}