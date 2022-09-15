resource "kubernetes_persistent_volume_claim" "jenkins_pvc_master" {
  metadata {
    name = "${var.project}-pvc-master"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
    labels = {
      vol = "${var.project}-pvc-master-node"
    }
  }
  spec {
    storage_class_name = "efs-sc"
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        "storage" = var.efs_storage_capacity_master_node
      }
    }
  }
}


resource "kubernetes_persistent_volume_claim" "jenkins_pvc_node" {
  metadata {
    name = "${var.project}-pvc-node"
    namespace = kubernetes_namespace.jenkins.metadata.0.name
    labels = {
      vol = "${var.project}-pvc-slave-node"
    }
  }
  spec {
    storage_class_name = "efs-sc"
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        "storage" = var.efs_storage_capacity_slave_node
      }
    }
  }
}