provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::729111267627:role/webfocus-eks"
  }
}
