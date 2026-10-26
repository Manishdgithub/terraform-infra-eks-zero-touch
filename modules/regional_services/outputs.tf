output "s3_bucket_arn" {
  description = "The ARN of the regional S3 bucket"
  value       = aws_s3_bucket.app_data.arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.app_state.name
}