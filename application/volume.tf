# resource "kubernetes_persistent_volume" "nginx_pv" {
#   metadata {
#     name = "nginx-pv"
#   }
#   spec {
#     storage_class_name = "efs-sc"
#     persistent_volume_reclaim_policy = "Retain"
#     capacity = {
#       storage =  var.efs_capacity
#     }
#     access_modes = ["ReadWriteMany"]
#     persistent_volume_source {
#       nfs {
#         path = "/"
#         server = data.terraform_remote_state.remote.outputs.eks_efs_fs_fsid
#       }
#     }
#   }
# }



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