output "application_instructions" {
  description = "Instructions to view the ALB URL once DNS propagates"
  value       = "Run 'kubectl get ingress -n game-2048' to view the provisioned Application Load Balancer address."
}
