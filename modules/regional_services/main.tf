data "aws_caller_identity" "current" {}

# Regional S3 Data Bucket
resource "aws_s3_bucket" "app_data" {
  bucket        = "company-app-data-${var.environment}-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.environment == "prod" ? false : true

  tags = {
    Name        = "${var.environment}-app-data"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Regional DynamoDB Table (State / Application Lock)
resource "aws_dynamodb_table" "app_state" {
  name         = "${var.environment}-app-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }

  tags = {
    Name        = "${var.environment}-dynamodb-table"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.environment}-app"
  retention_in_days = var.environment == "prod" ? 90 : 14

  tags = {
    Environment = var.environment
  }
}

# CloudWatch High CPU Alarm for Auto Scaling Group
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 75

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}