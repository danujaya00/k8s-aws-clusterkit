# File: modules/load_balancer/output.tf

output "alb_dns_name" {
  value = aws_lb.k8s_alb.dns_name
}
