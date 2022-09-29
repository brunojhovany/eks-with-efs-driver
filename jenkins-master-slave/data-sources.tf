data "terraform_remote_state" "remote" {
  backend = "local"
  config = {
    path = "../eks-cluster/terraform.tfstate"
  }
}

data "kubernetes_service" "jenkins" {
  metadata {
    name = kubernetes_service.jenkins-master.metadata.0.name
    namespace = kubernetes_namespace.jenkins.metadata.0.name
  }
}