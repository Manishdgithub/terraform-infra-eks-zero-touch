variable "aws_region" {
  type        = string
  description = "Target AWS deployment region"
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (dev, qc, or prod)"
}

variable "key_pair_name" {
  type        = string
  description = "Name for the aws_login EC2 key pair"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR address space block"
}

variable "availability_zones" {
  type        = list(string)
  description = "Two availability zones for multi-AZ high availability"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of 2 public subnet CIDRs"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of 2 private subnet CIDRs"
}

variable "instance_type" {
  type        = string
  description = "Instance size for backend EC2 servers"
}

variable "min_size" {
  type        = number
  description = "Minimum ASG instance capacity"
}

variable "max_size" {
  type        = number
  description = "Maximum ASG instance capacity"
}

variable "desired_capacity" {
  type        = number
  description = "Target ASG instance capacity"
}