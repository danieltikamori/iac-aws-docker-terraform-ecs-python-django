variable "repository_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "IAMRole" { # Then go to Main.tf in the environments and use this variable.
  type = string
}

variable "aws_region" {
  type = string
  default = "us-west-2"
}

variable "image_tag" {
  type = string
  default = "latest"
}

variable "aws_account_number" {
  type = string
}