terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.26"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "terraform"
}

locals {
  cluster_name = "${var.environment}-eks-cluster"
}

# 1. Automated RSA Key Pair Generation for SSH Login
resource "tls_private_key" "login_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "aws_login" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.login_key.public_key_openssh

  tags = {
    Name        = var.key_pair_name
    Environment = var.environment
  }
}

resource "local_file" "private_pem" {
  content         = tls_private_key.login_key.private_key_pem
  filename        = "${path.module}/${var.key_pair_name}.pem"
  file_permission = "0400"
}

# 2. Multi-AZ VPC Module (2 NAT Gateways - 1 per AZ, S3 Gateway Endpoint)
module "vpc" {
  source               = "../../modules/vpc"
  environment          = var.environment
  cluster_name         = local.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# 3. Security Groups Module
module "security" {
  source       = "../../modules/security"
  environment  = var.environment
  cluster_name = local.cluster_name
  vpc_id       = module.vpc.vpc_id
}

# 4. EKS Control Plane Module
module "eks" {
  source                    = "../../modules/eks"
  environment               = var.environment
  cluster_name              = local.cluster_name
  cluster_version           = "1.30"
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = module.security.eks_cluster_security_group_id
  node_role_arn             = module.asg.node_role_arn
}

# 5. Auto Scaling Group Data Plane (Worker Nodes)
module "asg" {
  source                             = "../../modules/asg"
  environment                        = var.environment
  cluster_name                       = local.cluster_name
  cluster_version                    = "1.30"
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  instance_type                      = var.instance_type
  private_subnet_ids                 = module.vpc.private_subnet_ids
  instance_security_group_id         = module.security.instance_security_group_id
  key_name                           = aws_key_pair.aws_login.key_name
  min_size                           = var.min_size
  max_size                           = var.max_size
  desired_capacity                   = var.desired_capacity
}

# 6. Regional Services Module
module "regional_services" {
  source      = "../../modules/regional_services"
  environment = var.environment
  asg_name    = module.asg.asg_name
}

# --- Dynamic Provider Authentication via AWS CLI exec ---

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region,
      "--profile",
      "terraform"
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region,
        "--profile",
        "terraform"
      ]
    }
  }

  # Isolate cache inside your local module directory so it ignores global Windows temp indexes
  repository_cache       = "${path.module}/.helm-cache"
  repository_config_path = "${path.module}/.helm-cache/repositories.yaml"
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region,
      "--profile",
      "terraform"
    ]
  }
}

# 7. Automated Addons & Application Deployment
module "addons" {
  source        = "../../modules/addons"
  cluster_name  = module.eks.cluster_name
  aws_region    = var.aws_region
  vpc_id        = module.vpc.vpc_id
  manifest_path = "${path.module}/../../2048-game.yaml"

  depends_on = [module.asg]
}