data "kubernetes_service" "nginx" {
  metadata {
    name = var.app
    namespace = var.namespace
  }
  depends_on = [
    kubernetes_deployment.nginx,
    kubernetes_service.nginx
  ]
}

data "terraform_remote_state" "remote" {
  backend = "local"
  config = {
    path = "../eks-cluster/terraform.tfstate"
  }
}

