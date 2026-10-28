output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "Deployment cluster name"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "Deployment cluster endpoint"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "Deployment cluster certificate authority data"
}