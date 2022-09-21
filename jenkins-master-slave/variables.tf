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

variable "jenkins_master_username" {
  description = "jenkins master node username"
  type = string
  default = "adminuser"
}

variable "jenkins_master_password" {
  description = "jenkins master node password"
  type = string
  sensitive = true
}

variable "jenkins_docker_image" {
  description = "jenkins docker image and version"
  type = string
  default = "jenkins/jenkins:lts"
}

variable "jenkins_sidecar_image" {
  description = "the sidecar container image for bootstrap configuration of jenkins user"
  type = string
  default = "jhovanylinkin/jenkins-sidecar-config"
}