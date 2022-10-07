data "terraform_remote_state" "remote" {
  backend = "local"
  config = {
    path = "../eks-cluster/terraform.tfstate"
  }
}
