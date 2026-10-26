# 1. Existing ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Controls public inbound traffic to the Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow inbound HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# 2. Control Plane Security Group
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.environment}-eks-cluster-sg"
  description = "Security group for EKS control plane ENIs"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-eks-cluster-sg"
    Environment = var.environment
  }
}

# 3. Worker Node (ASG Instances) Security Group
resource "aws_security_group" "instance_sg" {
  name        = "${var.environment}-app-server-sg"
  description = "Controls traffic to backend EC2 ASG worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP inbound from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "Allow SSH access on port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                        = "${var.environment}-app-server-sg"
    Environment                                 = var.environment
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# 4. Intersite EKS Rules
# Allow Worker Nodes to talk to each other (Pods & CNI)
resource "aws_security_group_rule" "nodes_internal" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.instance_sg.id
  source_security_group_id = aws_security_group.instance_sg.id
}

# Node -> Control Plane (API Server 443)
resource "aws_security_group_rule" "cluster_inbound_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.instance_sg.id
}

# Control Plane -> Node kubelet
resource "aws_security_group_rule" "nodes_inbound_from_cluster" {
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instance_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}

resource "aws_security_group_rule" "nodes_inbound_from_cluster_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.instance_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
}