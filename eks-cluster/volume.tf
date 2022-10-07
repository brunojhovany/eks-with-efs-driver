resource "aws_efs_file_system" "eks_efs_fs" {
  creation_token = "${aws_eks_cluster.this.name}-efs-1"

  tags = {
    Name = "${aws_eks_cluster.this.name}-efs-1"
  }
}

resource "aws_efs_mount_target" "eks_efs_mnt_target" {
  count           = var.availability_zones_count
  file_system_id  = aws_efs_file_system.eks_efs_fs.id
  subnet_id       = aws_subnet.private.*.id[count.index]
  security_groups = [aws_security_group.tf-efs-sg.id]
}

# resource "aws_efs_access_point" "eks_efs_access_pt" {
#   file_system_id = aws_efs_file_system.eks_efs_fs.id
# }

resource "aws_security_group" "tf-efs-sg" {
  name        = "tf-efs-sg"
  description = "communication to EFS"
  vpc_id      = aws_vpc.this.id

  egress = [{
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    description      = "egress all trafic"
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]
  ingress = [{
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    cidr_blocks      = flatten([cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 0), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 1), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 2), cidrsubnet(var.vpc_cidr, var.subnet_cidr_bits, 3)])
    description      = "Allow NFS trafic"
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }]

  tags = {
    Name = "tf-efs-sg"
  }
}

# resource "kubernetes_storage_class" "efs_storage_class" {
#   metadata {
#     name = "efs-sc"
#   }
#   storage_provisioner = "efs.csi.aws.com"
#   parameters = {
#     provisioningMode = "efs-ap"
#     fileSystemId     = aws_efs_file_system.eks_efs_fs.id
#     directoryPerms   = "700"
#     gidRangeStart    = "1000"                  # optional
#     gidRangeEnd      = "2000"                  # optional
#     basePath         = "/dynamic_provisioning" # optional
#   }
# }


module "efs_csi_driver" {
  source                           = "git::https://github.com/DNXLabs/terraform-aws-eks-efs-csi-driver.git"
  cluster_name                     = aws_eks_cluster.this.name
  cluster_identity_oidc_issuer     = aws_eks_cluster.this.identity.0.oidc.0.issuer
  cluster_identity_oidc_issuer_arn = aws_iam_openid_connect_provider.cluster.arn
  create_storage_class             = false
  depends_on = [
    aws_efs_mount_target.eks_efs_mnt_target
  ]
}
