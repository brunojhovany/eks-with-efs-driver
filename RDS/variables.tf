variable "project" {
  description = "Name to be used on all the resources as identifier. e.g. Project name, Application name"
  default     = "bruno-eks"
  type        = string
}

variable "region" {
  description = "The aws region. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html"
  type        = string
  default     = "us-east-1"
}

variable "webfocus_role" {
  description = "The webfocus role in aws"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    "Project"     = "bruno-eks"
    "Environment" = "Development"
    "Owner"       = "mjhovany"
  }
}

