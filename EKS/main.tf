# EKS Cluster
# ========================================================
resource "aws_eks_cluster" "eks-cluster" {
  name    = var.cluster.name
  version = var.cluster.version

  role_arn = aws_iam_role.eks-cluster-role.arn

  access_config {
    authentication_mode                         = var.cluster.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.cluster.grant_root_user_cluster_access_permissions
  }

  vpc_config {
    endpoint_private_access = var.cluster.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster.cluster_endpoint_public_access ? var.cluster.cluster_endpoint_public_access_cidrs : null
    security_group_ids      = [aws_security_group.cluster_additional_security_group.id]
    subnet_ids              = var.cluster.private_subnet_ids
  }

  enabled_cluster_log_types = var.cluster.enabled_log_types

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks-cmk.arn
    }
    resources = var.cluster.enable_secrets_encryption ? ["secrets"] : null
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster.name}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController
  ]
}


# EKS Nodegroup
# ========================================================
resource "aws_eks_node_group" "eks-node-group" {
  for_each = var.cluster.node_group

  cluster_name    = var.cluster.name
  node_group_name = each.value.node_group_name
  node_role_arn   = aws_iam_role.node-group-role.arn
  subnet_ids      = var.cluster.private_subnet_ids

  ami_type       = each.value.ami_type
  instance_types = each.value.instance_types

  launch_template {
    id      = aws_launch_template.eks-worker-node-lt[each.key].id
    version = "$Latest"
  }

  scaling_config {
    min_size     = each.value.min_size
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = try(each.value.labels, {})

  dynamic "taint" {
    for_each = [for t in try(each.value.taints, []) : t if can(t.key) && can(t.effect) && can(t.value)]

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-group-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node-group-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-group-AmazonEKSWorkerNodePolicy,
    aws_eks_cluster.eks-cluster
  ]
}

resource "aws_launch_template" "eks-worker-node-lt" {
  for_each = var.cluster.node_group

  name = "${each.value.node_group_name}-lt"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = each.value.imds_v2_mode
    http_put_response_hop_limit = each.value.imds_v2_token_hop_limit
    instance_metadata_tags      = "enabled"
  }

  vpc_security_group_ids = [aws_security_group.worker_node_security_group.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      "Name" = each.value.node_instance_name
    }
  }

  depends_on = [
    aws_security_group_rule.worker_node_egress_self,
    aws_security_group_rule.worker_node_egress_to_all,
    aws_security_group_rule.worker_node_ingress_cluster_high_ports,
    aws_security_group_rule.worker_node_ingress_dns_tcp_self,
    aws_security_group_rule.worker_node_ingress_dns_udp_self,
    aws_security_group_rule.worker_node_ingress_from_cluster,
    aws_security_group_rule.worker_node_ingress_kubelet_from_cluster,
    aws_security_group_rule.worker_node_ingress_self
  ]
}


# Fargate Profile
# ========================================================
resource "aws_eks_fargate_profile" "eks-fargate-profile" {
  count = var.cluster.create_fargate_profile == true ? 1 : 0

  cluster_name = aws_eks_cluster.eks-cluster.name

  fargate_profile_name   = var.cluster.fargate_profile.name
  pod_execution_role_arn = aws_iam_role.fargate-role[0].arn
  subnet_ids             = var.cluster.private_subnet_ids

  dynamic "selector" {
    for_each = var.cluster.fargate_profile.namespaces

    content {
      namespace = selector.value
      labels    = try(var.cluster.fargate_profile.labels_per_namespace[selector.value], null)
    }
  }

  depends_on = [aws_ec2_tag.add_subnet_tags]
}


# EKS Addon
# ========================================================
resource "aws_eks_addon" "eks-addon" {
  for_each = var.cluster.addon

  cluster_name = aws_eks_cluster.eks-cluster.name
  addon_name   = each.value

  depends_on = [aws_eks_node_group.eks-node-group]

  timeouts {
    create = "3m"
  }
}


# Cluster IAM Role
# ========================================================
resource "aws_iam_role" "eks-cluster-role" {
  name = "${var.cluster.name}-EKSClusterRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "cluster-cmk-use" {
  name        = "${var.cluster.name}-cmk-policy"
  description = "${var.cluster.name} cmk use policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:ListGrants",
          "kms:GetPublicKey"
        ]
        Effect   = "Allow"
        Resource = "${aws_kms_key.eks-cmk.arn}"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_CMKPolicy" {
  role       = aws_iam_role.eks-cluster-role.name
  policy_arn = aws_iam_policy.cluster-cmk-use.arn
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks-cluster-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  role       = aws_iam_role.eks-cluster-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachments_exclusive" "cluster_policy_delete" {
  role_name = aws_iam_role.eks-cluster-role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    aws_iam_policy.cluster-cmk-use.arn
  ]
}


# Nodegroup IAM Role
# ========================================================
resource "aws_iam_role" "node-group-role" {
  name = "${var.cluster.name}-EKSNodegroupRole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-group-role.name
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node-group-role.name
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-group-role.name
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node-group-role.name
}

resource "aws_iam_role_policy_attachments_exclusive" "node-group-policy-delete" {
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  role_name = aws_iam_role.node-group-role.name
}


# Fargate profile IAM Role
# ========================================================
resource "aws_iam_role" "fargate-role" {
  count = var.cluster.create_fargate_profile == true ? 1 : 0

  name = "${var.cluster.name}-eks-fargate-profile-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "fargate-AmazonEKSFargatePodExecutionRolePolicy" {
  count = var.cluster.create_fargate_profile == true ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate-role[0].name
}


# CMK
# ========================================================
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "eks-cmk" {
  description             = "EKS CMK"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 7
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "eks-key"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.eks-cluster-role.name}"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:ListGrants",
          "kms:GetPublicKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "eks-cmk-alias" {
  name          = "alias/eks-cmk"
  target_key_id = aws_kms_key.eks-cmk.id
}


# Cluster Additional Security Group
# ========================================================
resource "aws_security_group" "cluster_additional_security_group" {
  name        = "${var.cluster.name}-additional-sg"
  description = "${var.cluster.name} addtional security group"

  vpc_id = var.cluster.vpc_id

  tags = {
    Name                                        = "${var.cluster.name}-additional-sg"
    "kubernetes.io/cluster/${var.cluster.name}" = "owned"
  }

  ingress {
    from_port       = "443"
    to_port         = "443"
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_node_security_group.id]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [aws_security_group.worker_node_security_group]
}


# Worker node Security Group
# ========================================================
resource "aws_security_group" "worker_node_security_group" {
  name        = "${var.cluster.name}-worker-node-sg"
  description = "${var.cluster.name} worker node security group"

  vpc_id = var.cluster.vpc_id

  tags = {
    Name = "${var.cluster.name}-worker-node-sg"
  }
}

resource "aws_security_group_rule" "worker_node_ingress_from_cluster" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_node_security_group.id
  source_security_group_id = aws_security_group.cluster_additional_security_group.id

  depends_on = [aws_security_group.cluster_additional_security_group]
}

resource "aws_security_group_rule" "worker_node_ingress_kubelet_from_cluster" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_node_security_group.id
  source_security_group_id = aws_security_group.cluster_additional_security_group.id

  depends_on = [aws_security_group.cluster_additional_security_group]
}

resource "aws_security_group_rule" "worker_node_ingress_cluster_high_ports" {
  type                     = "ingress"
  from_port                = 1024
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_node_security_group.id
  source_security_group_id = aws_security_group.cluster_additional_security_group.id

  depends_on = [aws_security_group.cluster_additional_security_group]
}

resource "aws_security_group_rule" "worker_node_ingress_dns_tcp_self" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  security_group_id = aws_security_group.worker_node_security_group.id
  self              = true
}

resource "aws_security_group_rule" "worker_node_ingress_dns_udp_self" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  security_group_id = aws_security_group.worker_node_security_group.id
  self              = true
}

resource "aws_security_group_rule" "worker_node_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.worker_node_security_group.id
  self              = true
}

resource "aws_security_group_rule" "worker_node_egress_self" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.worker_node_security_group.id
  self              = true
}

resource "aws_security_group_rule" "worker_node_egress_to_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.worker_node_security_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}


# Attach Tag to VPC
# ========================================================
resource "aws_ec2_tag" "add_vpc_tags" {
  resource_id = var.cluster.vpc_id
  key         = "kubernetes.io/cluster/${var.cluster.name}"
  value       = "owned"
}


# Attach Tag to Subnet
# ========================================================
resource "aws_ec2_tag" "add_subnet_tags" {
  for_each = toset(var.cluster.private_subnet_ids)

  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster.name}"
  value       = "owned"
}

resource "aws_ec2_tag" "add_karpenter_tag" {
  for_each = var.cluster.add_karpenter_tag_to_subnet ? toset(var.cluster.private_subnet_ids) : []

  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster.name
}
