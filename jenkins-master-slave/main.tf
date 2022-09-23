provider "kubernetes" {
  config_path = "../${path.module}/kubeconfig"
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.project
  }
}

resource "kubernetes_config_map" "plugins" {
  metadata {
    name = "${var.project}-plugins"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
  }
  data = {
    "plugins.txt" = "${file("${path.module}/externals/plugins.txt")}"
  }
}

resource "kubernetes_config_map" "casc_config" {
  metadata {
    name = "${var.project}-casc-config"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
  }
  data = {
    "casc.yaml" = "${file("${path.module}/externals/casc.yaml")}"
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
        init_container {
          name = "${var.project}-install-plugins"
          image = var.jenkins_docker_image
          command = [ "jenkins-plugin-cli", "-f", "/usr/share/jenkins/ref/plugins.txt", "-d", "/var/jenkins_home/plugins"]
          volume_mount {
            name = "jenkins-home"
            mount_path =  "/var/jenkins_home"
          }
          volume_mount {
            name = "jenkins-plugins"
            mount_path = "/usr/share/jenkins/ref"
          }
        }
        container {
          name = var.project
          image = var.jenkins_docker_image
          # this env variable is for omit the initial septup of jenkins and installation of complements
          # env {
          #   name = "JAVA_OPTS"
          #   value = "-Djenkins.install.runSetupWizard=false"
          # }
          env {
            name = "ADMIN_PASSWORD"
            value = var.jenkins_master_password
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
            name = "jenkins-home"
            mount_path =  "/var/jenkins_home"
          }
        }
        volume {
          name = "jenkins-home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jenkins_pvc_master.metadata.0.name
          }
        }
        volume {
          name = "jenkins-plugins"
          config_map {
            name = kubernetes_config_map.plugins.metadata.0.name
          }
        }
      }
    }
  }
}


resource "kubernetes_job" "jenkins_bootstrap_config" {
  metadata {
    name = "${var.project}-jenkins-bootstrap-config"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "jenkins-bootstrap-config"
          image   = var.jenkins_sidecar_image
          command = ["/bin/bash", "-c", "./jenkins.sh"]
          env {
            name = "JENKINS_HOST"
            value = "jenkins-master.jenkins"
          }
          env {
            name = "JENKINS_ADMIN_PASSWORD"
            value = var.jenkins_master_password
          }
          volume_mount {
            name = "jenkins-home"
            mount_path =  "/var/jenkins_home"
          }
        }
        volume {
          name = "jenkins-home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.jenkins_pvc_master.metadata.0.name
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  depends_on = [
    kubernetes_deployment.jenkins-master
  ]
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