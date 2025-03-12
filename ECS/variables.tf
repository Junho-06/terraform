variable "ecs" {
  type = any
  default = {
    region = "ap-northeast-2"

    cluster = {
      name                  = "skills-ecs-cluster"
      containerInsightsMode = "enhanced" # disabled, enabled, enhanced
    }

    task_definition = {
      name = "skills-ecs-td"

      cpu    = 512
      memory = 1024

      cpu_architecture = "X86_64" # X86_64, ARM64

      container_definitions = [
        {
          name                 = "sample"
          image                = "junho1228/sample:python-v1"
          port                 = 8080
          healthcheck_path     = "/healthcheck"
          environment_variable = []
        },
        # {
        #   name             = "sampler"
        #   image            = "public.ecr.aws/g1s2t7w5/sampler:latest"
        #   port             = 8888
        #   healthcheck_path = "/dummy/health"
        #   environment_variable = [
        #     {
        #       name  = "PORT"
        #       value = "8888"
        #     },
        #     {
        #       name  = "UPSTREAM_ENDPOINT"
        #       value = "http://localhost:8080"
        #     },
        #     {
        #       name  = "IGNORE_PATH"
        #       value = "/favicon.ico"
        #     },
        #     {
        #       name  = "IGNORE_HEALTHCHECK"
        #       value = "1"
        #     }
        #   ]
        # }
      ]
    }

    service = {
      name = "skills-ecs-service"

      desired_task_count = 2
      min_task_count     = 2
      max_task_count     = 4
      target_metric      = "CPU" # CPU, Memory
      target_percent     = 70
      scale_out_cooldown = 60
      scale_in_cooldown  = 120

      availability_zone_rebalancing = "ENABLED" # ENABLED, DISABLED

      vpc_id           = ""
      vpc_cidr         = ""
      task_subnet_ids  = ["", ""]
      assign_public_ip = false
    }
  }
}
