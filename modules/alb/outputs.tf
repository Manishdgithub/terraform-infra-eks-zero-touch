output "alb_dns_name" {
  description = "Publicly reachable DNS hostname of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "Amazon Resource Name (ARN) of the ALB"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the ALB Target Group to bind with the Auto Scaling Group"
  value       = aws_lb_target_group.app.arn
}