# 1. Fetch AWS-maintained EKS AMI for the cluster version
data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/image_id"
}

# 2. Worker Node IAM Role and Policies
resource "aws_iam_role" "node" {
  name = "${var.environment}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# Official AWS Load Balancer Controller IAM Policy dynamically fetched
data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "lbc_policy" {
  name        = "${var.environment}-AWSLoadBalancerControllerIAMPolicy"
  description = "Allows EKS worker nodes to manage ALBs and Target Groups dynamically"
  policy      = data.http.lbc_iam_policy.response_body
}

resource "aws_iam_role_policy_attachment" "node_alb_controller" {
  policy_arn = aws_iam_policy.lbc_policy.arn
  role       = aws_iam_role.node.name
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.environment}-eks-node-profile"
  role = aws_iam_role.node.name
}

# 3. Launch Template (Configured with IMDSv2 hop limit = 2 for LBC pod metadata access)
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-template-"
  image_id      = data.aws_ssm_parameter.eks_ami.value
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.node.arn
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.instance_security_group_id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -o xtrace
    /etc/eks/bootstrap.sh ${var.cluster_name} \
      --b64-cluster-ca '${var.cluster_certificate_authority_data}' \
      --apiserver-endpoint '${var.cluster_endpoint}'
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name                                        = "${var.environment}-eks-worker-node"
      Environment                                 = var.environment
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 4. Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "${var.environment}-asg-"
  vpc_zone_identifier = var.private_subnet_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes        = [target_group_arns, load_balancers]
    create_before_destroy = true
  }
}
