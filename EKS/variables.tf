variable "cluster" {
  type        = any
  description = "Map for EKS cluster"

  default = {
    region = "ap-northeast-2"

    name    = ""
    version = "1.31"

    authentication_mode                        = "API_AND_CONFIG_MAP" # CONFIG_MAP, API, API_AND_CONFIG_MAP
    grant_root_user_cluster_access_permissions = true

    vpc_id             = ""
    vpc_cidr           = ""
    private_subnet_ids = ["", ""]

    add_karpenter_tag_to_subnet = true

    cluster_endpoint_private_access      = true # 2개 다 true로 설정시 private and public
    cluster_endpoint_public_access       = false
    cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

    enable_secrets_encryption = true

    # "audit", "api", "authenticator", "scheduler", "controllerManager"
    enabled_log_types = ["audit", "api", "authenticator", "scheduler", "controllerManager"]

    # addon 생성 3분 후에 timeout 되고 addon 설치만 된 상태로 남게됨
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
        node_group_name    = ""
        node_instance_name = ""

        imds_v2_mode            = "required" # required, optional
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

    create_fargate_profile = false
    fargate_profile = {
      name = ""

      namespaces = ["test", "custom", "no-label"]

      labels_per_namespace = {

        "test" = {
          "env" = "test"
        }

        "custom" = {
          "env" = "custom"
        }
      }
    }
  }
}
