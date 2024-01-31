# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
data "aws_caller_identity" "current" {}
locals {
  resource_name = "${var.project_name}-${var.environment_name}"
}
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_kl_cluster_role" {
  name               = "${local.resource_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_kl_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_kl_cluster_role.name
}
resource "aws_kms_key" "eks_secret_key" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 10
  policy                  = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "Enable IAM User Permissions",
        "Effect": "Allow",
        "Principal": {
          "AWS": "*"  # Replace with your IAM user ARN
        },
        "Action": "kms:*",
        "Resource": "*"
      },
      {
        "Sid": "Allow EKS to use the key",
        "Effect": "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action": [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource": "*"
      }
    ]
  })
}
# Security group for eks cluster
resource "aws_security_group" "eks-cluster" {
  name        = "${local.resource_name}-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

 tags = {
    Name = "${local.resource_name}-cluster-sg"
    Environment = "${var.environment_name}"
  }
}
# Security group ingress rules
resource "aws_security_group_rule" "demo-cluster-ingress-workstation-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.eks-cluster.id
  to_port           = 443
  type              = "ingress"
}
resource "time_sleep" "wait_for_eks" {
  create_duration = "15m"
}
# EKS cluster with custom configs
resource "aws_eks_cluster" "eks" {
  encryption_config {
         resources = [ "secrets" ]
         provider {
             key_arn = aws_kms_key.eks_secret_key.arn
         }
     }
  name     = "${local.resource_name}-cluster"
  role_arn = aws_iam_role.eks_kl_cluster_role.arn
  version                   = var.cluster_version
  enabled_cluster_log_types = var.enabled_cluster_log_types

  vpc_config {
    security_group_ids = [aws_security_group.eks-cluster.id]
    subnet_ids         = var.subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSVPCResourceController,
  ]

}

# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_node_role" {
  name               = "${local.resource_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# EKS on demand nodegroup resource
resource "aws_eks_node_group" "eks_on_demand_ng" {
  count = var.create_on_demand_ng ? 1: 0
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.project_name}-on_demaond-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = var.on_demand_instance_types
  capacity_type = "ON_DEMAND"
  scaling_config {
    desired_size = var.eks_on_demand_desired_size
    max_size     = var.eks_on_demand_max_size
    min_size     = var.eks_on_demand_min_size
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}
# EKS on spot nodegroup resource
resource "aws_eks_node_group" "eks_spot_ng" {

  count = var.create_spot_ng ? 1: 0
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${local.resource_name}-spot-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.private_subnet_ids
  # added by me
  instance_types = var.spot_instance_types
  capacity_type = "SPOT"
  ##
  scaling_config {
    desired_size = var.eks_spot_desired_size
    max_size     = var.eks_spot_max_size
    min_size     = var.eks_spot_min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}

# setup oped ID connector setup
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

# Setup IAM Role and policy for aws alb ingress controller 
resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  name               = "aws-load-balancer-controller" 
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  
  policy=file("${path.module}/AWSLoadBalancerController.json")
  name   = "AWSLoadBalancerController"    
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

# Setup helm provider 
provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.id]
      command     = "aws"
      #env = {
       # AWS_PROFILE = var.aws_profile_name  # Replace with your AWS profile name
      #}
    }
  }
}
# Deploy aws alb ingress-controller through helm chart
resource "helm_release" "aws-load-balancer-controller" {
  name = "aws-load-balancer-controller"

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.1"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks.id
  }

  set {
    name  = "image.tag"
    value = "v2.4.2"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  depends_on = [
    aws_eks_node_group.eks_spot_ng,
    aws_eks_node_group.eks_on_demand_ng,

    aws_iam_role_policy_attachment.aws_load_balancer_controller_attach
  ]
}

##### METRIC CLUSTER ###############
resource "helm_release" "metrics_server" {
  depends_on = [aws_eks_cluster.eks, aws_eks_node_group.eks_on_demand_ng, aws_eks_node_group.eks_spot_ng]
  name             = "metrics-server"
  namespace        = "metrics-server"
  version          = "3.10.0"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  create_namespace = true

  set {
    name  = "replicas"
    value = 1
  }

}


########## EKS Cluster Autoscaler######################
# Policy
data "aws_iam_policy_document" "eks_cluster_autoscaler_policy_document" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeImages",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup",
    ]

    resources = ["*"]
  }


}
# Autoscaler role and policy
resource "aws_iam_policy" "eks_cluster_autoscaler_policy" {

  count = var.enable_cluster_autoscaler ? 1 : 0
  name = "${local.resource_name}-eks-cluster-autoscaler-policy"



  path        = "/"
  description = "Policy for cluster autoscaler service"

  policy = data.aws_iam_policy_document.eks_cluster_autoscaler_policy_document[0].json
}


data "aws_iam_policy_document" "eks_oidc_assume_policy_document" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"

      values = ["sts.amazonaws.com", "system:serviceaccount:cluster-autoscaler:cluster-autoscaler-aws-cluster-autoscaler"]

    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}



resource "aws_iam_role" "eks_cluster_autoscaler_role" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "${local.resource_name}-eks-ClusterAutoscalerRole"





  assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_policy_document[count.index].json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_autoscaler_role_attachment" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  role       = aws_iam_role.eks_cluster_autoscaler_role[count.index].name
  policy_arn = aws_iam_policy.eks_cluster_autoscaler_policy[count.index].arn
}

# Cluster autoscaler helm chart
resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  #  depends_on = [
  #    aws_iam_role_policy_attachment.eks_cluster_autoscaler_role_attachment
  #  ]
  depends_on = [aws_eks_cluster.eks, aws_eks_node_group.eks_on_demand_ng, aws_eks_node_group.eks_spot_ng]




  name             = "cluster-autoscaler"
  namespace        = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = "9.29.0"
  create_namespace = true

  set {
    name  = "awsRegion"
    value = var.aws_region
  }
  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.eks_cluster_autoscaler_role[count.index].arn
    type  = "string"
  }
  set {
    name  = "autoDiscovery.clusterName"
    value = aws_eks_cluster.eks.id
  }
  set {
    name  = "rbac.create"
    value = "true"
  }
  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = "2m"  # Adjust the delay duration as needed
  }
  set {
    name= "extraArgs.scale-down-unneeded-time"
    value = "2m"
  }
}



