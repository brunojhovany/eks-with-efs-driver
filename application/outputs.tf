output "external_ip_service" {
  value = data.kubernetes_service.nginx #.status.0.load_balancer.0.ingress.0.hostname
  
  depends_on = [
    kubernetes_service.nginx
  ]
}