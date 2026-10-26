variable "environment" {
  type        = string
  description = "Target deployment environment identifier (e.g., dev, qc, prod)"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name used for Kubernetes subnet discovery tags"
}

variable "vpc_cidr" {
  type        = string
  description = "The primary IPv4 CIDR block for the Virtual Private Cloud (VPC)"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of exactly 2 distinct Availability Zones for multi-AZ high availability"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of 2 IPv4 CIDR blocks for the public subnets where ALBs and NAT GWs reside"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of 2 IPv4 CIDR blocks for the private subnets where application servers reside"
}