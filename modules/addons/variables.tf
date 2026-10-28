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

variable "git_repo_url" {
  type        = string
  description = "git repo url"
}

variable "git_target_revision" {
  type        = string
  description = "git repo target revision"
}

variable "kubernetes_deployment_file_name" {
  type        = string
  description = "kubernetes deployment file name"
}