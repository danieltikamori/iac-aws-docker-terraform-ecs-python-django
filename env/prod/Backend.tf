terraform {
  backend "s3" {
    bucket = "terraform-state-tikamori"
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
  }
}
