output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Control Plane Endpoint"
  value       = module.eks.cluster_endpoint
}

output "get_kubeconfig_command" {
  description = "Command to configure kubectl locally"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name} --profile terraform"
}

output "application_access" {
  description = "How to access the 2048 application"
  value       = "Run: kubectl get ingress ingress-2048 -n game-2048 (ALB provisions in ~2 mins)"
}

output "key_pair_name" {
  description = "The registered EC2 Key Pair name"
  value       = aws_key_pair.aws_login.key_name
}

output "private_key_file_path" {
  description = "Local path to the downloaded private SSH .pem key"
  value       = local_file.private_pem.filename
}

output "s3_bucket_arn" {
  description = "ARN of the created regional S3 bucket"
  value       = module.regional_services.s3_bucket_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.regional_services.dynamodb_table_name
}
