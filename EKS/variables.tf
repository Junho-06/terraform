variable "cluster" {
  type        = any
  description = "Map for EKS cluster"

  default = {
    name    = "skills-cluster"
    version = "1.31"

    authentication_mode                        = "API_AND_CONFIG_MAP" # CONFIG_MAP, API
    grant_root_user_cluster_access_permissions = true

    vpc_id             = "vpc-01484ff90e8244010"
    vpc_cidr           = "10.0.0.0/16"
    cluster_subnet_ids = ["subnet-01814993f62ce6909", "subnet-04a41e13e7d44752f"]

    cluster_endpoint_private_access      = true # 2개 다 true로 설정시 private and public
    cluster_endpoint_public_access       = false
    cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

    enable_secrets_encryption = true

    enabled_log_types = ["audit", "api", "authenticator", "scheduler", "controllerManager"]

    addon = {
      1 = "coredns",
      2 = "kube-proxy",
      3 = "vpc-cni",
      4 = "eks-pod-identity-agent",
      5 = "eks-node-monitoring-agent",
      6 = "metrics-server"
    }

    node_group = {
      node_group_1 = {
        node_group_name         = "skills-worker-ng"
        worker_ec2_name         = "skills-worker-node"
        imds_v2_mode            = "required" # optional
        imds_v2_token_hop_limit = 2

        min_size     = 2
        desired_size = 2
        max_size     = 8

        # AL2_x86_64, AL2_ARM_64
        # BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64
        # AL2023_x86_64_STANDARD, AL2023_ARM_64_STANDARD
        ami_type       = "AL2023_x86_64_STANDARD"
        instance_types = ["t3.medium"]

        labels = {
          #management = "addon"
        }
        taints = [
          {
            #effect = "NO_SCHEDULE"
            #key    = "management"
            #value  = "addon"
          }
        ]
      }
    }
  }
}
