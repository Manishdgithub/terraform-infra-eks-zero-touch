variable "environment" {
  type        = string
  description = "Deployment environment identifier"
}

variable "asg_name" {
  type        = string
  description = "Target ASG name to bind CloudWatch alarms to"
}