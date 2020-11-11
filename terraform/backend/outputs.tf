output "external_ip" {
  value = kubernetes_service.backend.load_balancer_ingress[0].ip 
}
