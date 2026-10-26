variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "aws_region" {
  type        = string
  description = "AWS Deployment Region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EKS is hosted"
}

variable "manifest_path" {
  type        = string
  description = "Absolute or relative path to 2048-game.yaml"
}
