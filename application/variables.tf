variable "namespace" {
    description = "namespace for app"
    default = "whoami"
}

variable "app" {
    description = "app name"
    default = "whoami"
}

variable "efs_capacity" {
  description = "capacity for efs persistent volume"
  default = "2Gi"
  type = string
}