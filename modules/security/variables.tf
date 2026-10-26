variable "environment" {
  type        = string
  description = "Deployment environment identifier"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID to which the security groups belong"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name used for tagging security groups"
}