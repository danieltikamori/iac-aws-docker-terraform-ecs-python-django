terraform {
  backend "s3" {
    bucket = "terraform-state-alura-iac"
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
  }
}
