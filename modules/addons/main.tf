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

# 1. AWS Load Balancer Controller Service Account
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

# 3. Deploy Argo CD via Helm (Creates and manages 'argocd' namespace natively)
resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "7.7.0"

  wait    = true
  timeout = 600

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
}

# 4. Declarative GitOps Application CRD (Finalizer removed for clean teardown)
resource "kubectl_manifest" "argocd_git_application" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: game-2048
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: '${var.git_repo_url}'
        targetRevision: '${var.git_target_revision}'
        path: '.'
        directory:
          include: '${var.kubernetes_deployment_file_name}'
      destination:
        server: 'https://kubernetes.default.svc'
        namespace: game-2048
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [
    helm_release.argocd,
    helm_release.aws_load_balancer_controller
  ]
}