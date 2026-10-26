variable "environment" {
  type = string
  description = "Deployment environment identifier"
}

variable "cluster_name" {
  type = string
  description = "Deployment cluster name"
}

variable "cluster_version" {
  type    = string
  default = "1.30"
  description = "Deployment cluster version"
}

variable "private_subnet_ids" {
  type = list(string)
  description = "Deployment private subnet ids"
}

variable "cluster_security_group_id" {
  type = string
  description = "Deployment cluster security group id"
}

variable "node_role_arn" {
  type        = string
  description = "IAM Role ARN of the ASG worker nodes to grant cluster join access"
}