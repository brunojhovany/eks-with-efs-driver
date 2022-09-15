variable "region" {
  description = "The aws region. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Name to be used on all the resources as identifier. e.g. Project name, Application name"
  default     = "jenkins"
  type        = string
}

variable "efs_storage_capacity_master_node" {
  description = "Storage capacity for jenkins master node"
  default     = "40Gi"
  type        = string
}

variable "efs_storage_capacity_slave_node" {
  description = "Storage capacity for jenkins slave node"
  default     = "80Gi"
  type        = string
}

variable "webfocus_role" {
  description = "The webfocus role in aws"
  type        = string
}