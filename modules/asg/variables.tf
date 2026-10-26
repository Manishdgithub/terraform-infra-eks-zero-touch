variable "environment" {
  type        = string
  description = "Deployment environment identifier"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type (e.g., t3.micro, t3.small, t3.medium)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for backend EC2 instance deployment"
}

variable "instance_security_group_id" {
  type        = string
  description = "Security group ID attached to backend EC2 instances"
}

variable "target_group_arn" {
  type        = string
  default     = null
  description = "Optional target group ARN if using manual ALB target groups"
}

variable "key_name" {
  type        = string
  description = "The EC2 key pair name (aws_login) configured for SSH logins"
}

variable "min_size" {
  type        = number
  description = "Minimum number of instances running in the ASG"
}

variable "max_size" {
  type        = number
  description = "Maximum capacity of instances the ASG can scale up to"
}

variable "desired_capacity" {
  type        = number
  description = "Target count of healthy instances maintained by ASG"
}

variable "cluster_name" {
  type        = string
  description = "Deployment cluster name"
}

variable "cluster_version" {
  type        = string
  default     = "1.30"
  description = "Deployment cluster version"
}

variable "cluster_endpoint" {
  type        = string
  description = "Deployment cluster endpoint"
}

variable "cluster_certificate_authority_data" {
  type        = string
  description = "Deployment cluster certificate authority data"
}
