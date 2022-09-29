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

resource "kubernetes_config_map" "casc_file" {
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
        # In this step we install plugins
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
          env {
            name = "JAVA_OPTS"
            value = "-Djenkins.install.runSetupWizard=false"
          }
          env {
            name = "ADMIN_PASSWORD"
            value = var.jenkins_master_password
          }
          env {
            name = "CASC_JENKINS_CONFIG"
            value = "/var/jenkins_home/casc_config/casc.yaml"
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
          volume_mount {
            name = "jenkins-casc"
            mount_path =  "/var/jenkins_home/casc_config"
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
        volume {
          name = "jenkins-casc"
          config_map {
            name = kubernetes_config_map.casc_file.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_account" "jenkins-master" {
  metadata {
    name = "${var.project}-master"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
  }
}


resource "kubernetes_role" "jenkins-role" {
  metadata {
    name = "${var.project}-master"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
  }
  rule {
    api_groups = [ "*" ]
    resources = [ "pods" ]
    verbs = [ "create","delete","get","list","patch","update","watch" ]
  }
  rule {
    api_groups = [ "*" ]
    resources = [ "pods/exec" ]
    verbs = [ "create","delete","get","list","patch","update","watch" ]
  }
  rule {
    api_groups = [ "*" ]
    resources = [ "pods/log" ]
    verbs = ["get","list","watch" ]
  }
  rule {
    api_groups = [ "*" ]
    resources = [ "events" ]
    verbs = [ "get","list","watch" ]
  }
  rule {
    api_groups = [ "*" ]
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
    namespace = kubernetes_namespace.jenkins.metadata.0.name
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