provider "kubernetes" {
  # host                   = data.aws_eks_cluster.cluster.endpoint
  # token                  = data.aws_eks_cluster_auth.cluster.token
  # cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  config_path = "../${path.module}/kubeconfig"
}


resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx"
  }
}


resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.nginx.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "MyNginxApp"
      }
    }
    template {
      metadata {
        labels = {
          app = "MyNginxApp"
        }
      }
      spec {
        volume {
          name = "nginx-pvc"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.nginx_pvc.metadata.0.name
          }
        }
        container {
          image = "nginx"
          name  = "nginx-container"
          port {
            container_port = 80
          }
          volume_mount {
            mount_path = "/data"
            name = "nginx-pvc"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.nginx.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.nginx.spec.0.template.0.metadata.0.labels.app
    }
    type = "LoadBalancer"
    port {
      port        = 80
      target_port = 80
    }
  }
  depends_on = [
    kubernetes_deployment.nginx
  ]
}
