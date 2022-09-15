provider "aws" {
  region = var.region

  assume_role {
    role_arn = var.webfocus_role
  }
}