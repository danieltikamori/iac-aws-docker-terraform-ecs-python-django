variable "repository_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "IAMRole" { # Then go to Main.tf in the environments and use this variable.
  type = string
}
