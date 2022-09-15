provider "kubernetes" {
  config_path = "../${path.module}/kubeconfig"
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.project
  }
}

resource "kubernetes_deployment" "jenkins-master" {
  metadata {
    name = "${var.project}-master"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
  }
  spec {
    selector {
      match_labels = {
        app = "${var.project}-master"
      }
    }
    replicas = 1
    template {
      metadata {
        labels = {
          app = "${var.project}-master"
        }
      
      }
      spec {
        container {
          name = var.project
          image = "jenkins/jenkins"
          env {
            name = "JAVA_OPTS"
            value = "-Djenkins.install.runSetupWizard=false"
          }
          port {
            name = "http-port"
            container_port = "8080"
          }
          port {
            name = "jnlp-port"
            container_port = "50000"
          }
          volume_mount {
            name = kubernetes_persistent_volume_claim.jenkins_pvc_master.metadata.0.name
            mount_path =  "/var/jenkins_home"
          }
        }
        volume {
          name = kubernetes_persistent_volume_claim.jenkins_pvc_master.metadata.0.name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jenkins_pvc_master.metadata.0.name
          }
        }
      }
    }
  }
}


resource "kubernetes_role" "jenkins-role" {
  metadata {
    name = "${var.project}-master"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
  }
  rule {
    api_groups = [ "" ]
    resources = [ "pods" ]
    verbs = [ "create","delete","get","list","patch","update","watch" ]
  }
  rule {
    api_groups = [ "" ]
    resources = [ "pods/exec" ]
    verbs = [ "create","delete","get","list","patch","update","watch" ]
  }
  rule {
    api_groups = [ "" ]
    resources = [ "pods/log" ]
    verbs = ["get","list","watch" ]
  }
  rule {
    api_groups = [ "" ]
    resources = [ "events" ]
    verbs = [ "get","list","watch" ]
  }
  rule {
    api_groups = [ "" ]
    resources = [ "secrets" ]
    verbs = [ "get" ]
  }
}

resource "kubernetes_role_binding" "jenkins-master-rb" {
  metadata {
    name = "${var.project}-master"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = kubernetes_role.jenkins-role.metadata.0.name
  }
  subject {
    kind = "ServiceAccount"
    name = kubernetes_role.jenkins-role.metadata.0.name
  }
}


resource "kubernetes_service" "jenkins-master" {
  metadata {
    name = "${var.project}-master"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
  }
  spec {
    type = "LoadBalancer"
    port {
      port = 80
      target_port = 8080
      name = "${var.project}-master"
    }
    port {
      port = 50000
      target_port = 50000
      name = "${var.project}-jnlp"
    }
    selector = {
      "app" = "${var.project}-master"
    }
  }
}


# EKS Cluster IAM Role
/* resource "aws_iam_role" "jenkins_master" {
  name = "${var.project}-role"

  assume_role_policy = <<POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "cloudformation:CreateUploadBucket",
                    "cloudformation:ListStacks",
                    "cloudformation:CancelUpdateStack",
                    "cloudformation:ExecuteChangeSet",
                    "cloudformation:ListChangeSets",
                    "cloudformation:ListStackResources",
                    "cloudformation:DescribeStackResources",
                    "cloudformation:DescribeStackResource",
                    "cloudformation:CreateChangeSet",
                    "cloudformation:DeleteChangeSet",
                    "cloudformation:DescribeStacks",
                    "cloudformation:ContinueUpdateRollback",
                    "cloudformation:DescribeStackEvents",
                    "cloudformation:CreateStack",
                    "cloudformation:DeleteStack",
                    "cloudformation:UpdateStack",
                    "cloudformation:DescribeChangeSet",
                    "s3:PutBucketPublicAccessBlock",
                    "s3:CreateBucket",
                    "s3:DeleteBucketPolicy",
                    "s3:PutEncryptionConfiguration",
                    "s3:PutBucketPolicy",
                    "s3:DeleteBucket"
                ],
                "Resource": "*"
            }
        ]
    }
POLICY
} */

/* resource "aws_iam_role_policy_attachment" "jenkins_AWSCloudFormationStackExecutionRole" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationStackExecutionRole"
  role       = aws_iam_role.jenkins_master.name
} */