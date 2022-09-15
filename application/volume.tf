resource "kubernetes_persistent_volume_claim" "nginx_pvc" {
  metadata {
    name = "nginx-pvc"
    namespace = kubernetes_namespace.nginx.metadata.0.name
    labels = {
      vol = "nginx_store_pvc"
    }
  }
  spec {
    storage_class_name = "efs-sc"
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        "storage" = var.efs_capacity
      }
    }
  }
}