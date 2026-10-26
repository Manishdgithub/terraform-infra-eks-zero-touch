terraform {
  required_providers {
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
  }
}

# 1. Plain ServiceAccount for the AWS Load Balancer Controller in kube-system
resource "kubernetes_service_account" "lbc_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
    }
  }
}

# 2. Deploy AWS Load Balancer Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.lbc_sa.metadata[0].name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }
}

# 3. Parse 2048-game.yaml documents with static keys at plan time
locals {
  raw_manifests = [
    for doc in split("---", file(var.manifest_path)) : trimspace(doc) if trimspace(doc) != ""
  ]
  manifest_map = {
    for idx, doc in local.raw_manifests : tostring(idx) => doc
  }
}

resource "kubectl_manifest" "app_resources" {
  for_each  = local.manifest_map
  yaml_body = each.value

  # Ensures controller pods are installed and running before the ingress is processed
  depends_on = [helm_release.aws_load_balancer_controller]
}
