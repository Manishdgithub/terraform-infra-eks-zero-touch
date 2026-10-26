output "vpc_id" {
  description = "The unique ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs corresponding to public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs corresponding to private subnets"
  value       = aws_subnet.private[*].id
}