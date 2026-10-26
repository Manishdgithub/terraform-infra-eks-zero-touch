variable "environment" {
  type        = string
  description = "Deployment environment identifier"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where the target group is registered"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs where ALB interfaces will be deployed"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID allowing inbound HTTP/HTTPS traffic to ALB"
}