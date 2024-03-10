module "prod" {
  source = "../../infra"

  aws_account_number = "273917849797"

  repository_name = "production" # Always use lowercase letters, no special characters or numbers or it may not work properly.

  environment = "prod"

  IAMRole = "prod" # After creating the variable, use the name of the variable in this field. This will create an AWS IAM role with that specific name and attach it to the ECS service.

  aws_region = "us-west-2"

  image_tag = "latest"
}

locals {

depends_on = [aws_ecr_repository.ecr_repository]
## Substitute below values to match your AWS account, region & profile
  aws_account = "273917849797" # AWS account
  aws_region  = "us-west-2"      # AWS region
  aws_profile = "docker-push-to-ecr" # AWS profile
  environment = "prod"

  # ECR docker registry URI
  ecr_reg   = "${local.aws_account}.dkr.ecr.${local.aws_region}.amazonaws.com" 
  
  ecr_repo  = "production" # ECR repo name
  image_tag = "latest"  # image tag

  dkr_img_src_path = "../../env/${local.environment}/docker-src"

  dkr_img_src_sha256 = sha256(join("", [for f in fileset(".", "${local.dkr_img_src_path}/**") : file(f)]))

  dkr_build_cmd = <<-EOT
      docker buildx build -t ${local.ecr_reg}/${local.ecr_repo}:${local.image_tag} 
            -f ${local.dkr_img_src_path}/Dockerfile .

        aws ecr get-login-password --region ${local.aws_region} | 
            docker login --username AWS --password-stdin ${local.ecr_reg}

        docker push ${local.ecr_reg}/${local.ecr_repo}:${local.image_tag}
    EOT

}

variable "force_image_rebuild" {
  type    = bool
  default = false
}

# local-exec for build and push of docker image
resource "null_resource" "build_push_dkr_img" {
  triggers = {
    detect_docker_source_changes = var.force_image_rebuild == true ? timestamp() : local.dkr_img_src_sha256
  }
  provisioner "local-exec" {
    command = local.dkr_build_cmd
  }
}

output "trigged_by" {
  value = null_resource.build_push_dkr_img.triggers
}

output "DNS_alb" {
  value = module.prod.DNS # Outputs the DNS address to make easier to get the Load Balancer DNS. This is useful when you need to add it manually in your /etc/hosts file for example.
}
