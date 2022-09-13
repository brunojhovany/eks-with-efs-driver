# output "cluster_name" {
#   value = aws_eks_cluster.this.name
# }

# output "cluster_endpoint" {
#   value = aws_eks_cluster.this.endpoint
# }

# output "cluster_ca_certificate" {
#   value = aws_eks_cluster.this.certificate_authority[0].data
# }


locals {
  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${aws_eks_cluster.this.certificate_authority.0.data}
    server: ${aws_eks_cluster.this.endpoint}
  name: ${aws_eks_cluster.this.arn}
contexts:
- context:
    cluster: ${aws_eks_cluster.this.arn}
    user: ${aws_eks_cluster.this.arn}
  name: ${aws_eks_cluster.this.arn}
current-context: ${aws_eks_cluster.this.arn}
kind: Config
preferences: {}
users:
- name: ${aws_eks_cluster.this.arn}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args: 
      - --region
      - ${var.region}
      - eks
      - get-token
      - --cluster-name
      - "${aws_eks_cluster.this.name}"
      - --profile
      - default
      - --role
      - ${var.webfocus_role}
      command: aws
      env: null
      interactiveMode: IfAvailable
      provideClusterInfo: false

KUBECONFIG
}

resource "local_file" "kubeconfig" {
  filename = "../${path.module}/kubeconfig"
  content  = local.kubeconfig
  file_permission = "400"
}

output "eks_efs_fs_fsid" {
  value = aws_efs_file_system.eks_efs_fs.id
}