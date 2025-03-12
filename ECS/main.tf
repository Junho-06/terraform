# ECS Cluster
# ========================================================
resource "aws_ecs_cluster" "ecs-cluster" {
  name = var.ecs.cluster.name

  setting {
    name  = "containerInsights"
    value = var.ecs.cluster.containerInsightsMode
  }
}

resource "aws_ecs_cluster_capacity_providers" "fargate_capacity_provider" {
  cluster_name = aws_ecs_cluster.ecs-cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}


# Task Definition
# ========================================================
resource "aws_ecs_task_definition" "task-definition" {
  family                   = var.ecs.task_definition.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.ecs.task_definition.cpu_architecture
  }

  cpu    = var.ecs.task_definition.cpu
  memory = var.ecs.task_definition.memory

  execution_role_arn = aws_iam_role.task_execution_role.arn
  task_role_arn      = aws_iam_role.task_role.arn

  container_definitions = jsonencode([for k, v in var.ecs.task_definition.container_definitions : {
    name      = v.name
    image     = v.image
    essential = true
    portMappings = [
      {
        containerPort = v.port
        hostPort      = v.port
      }
    ]
    healthcheck = {
      command = ["CMD-SHELL", "curl -f http://localhost:${v.port}${v.healthcheck_path} || exit 1"]
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
        awslogs-region        = var.ecs.region
        awslogs-stream-prefix = v.name
        awslogs-create-group  = "true"
      }
    }
    environment = v.environment_variable
  }])
}


# ECS Service
# ========================================================
resource "aws_ecs_service" "ecs-service" {
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.task-definition.arn

  name          = var.ecs.service.name
  desired_count = var.ecs.service.desired_task_count

  launch_type = "FARGATE"

  availability_zone_rebalancing = var.ecs.service.availability_zone_rebalancing

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = var.ecs.service.task_subnet_ids
    security_groups  = [aws_security_group.ecs-task-sg.id]
    assign_public_ip = var.ecs.service.assign_public_ip
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity       = var.ecs.service.min_task_count
  max_capacity       = var.ecs.service.max_task_count
  resource_id        = "service/${var.ecs.cluster.name}/${var.ecs.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name        = "scaling"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = var.ecs.service.target_percent

    disable_scale_in = false

    scale_out_cooldown = var.ecs.service.scale_out_cooldown
    scale_in_cooldown  = var.ecs.service.scale_in_cooldown

    predefined_metric_specification {
      predefined_metric_type = var.ecs.service.target_metric == "CPU" ? "ECSServiceAverageCPUUtilization" : var.ecs.service.target_metric == "Memory" ? "ECSServiceAverageMemoryUtilization" : null
    }
  }
}


# Task IAM role
# ========================================================
data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${var.ecs.task_definition.name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_execution_role_secret_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachments_exclusive" "task_execution_role_policy_exclusive" {
  role_name = aws_iam_role.task_execution_role.name
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]
}

resource "aws_iam_role" "task_role" {
  name               = "${var.ecs.task_definition.name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/application/${var.ecs.cluster.name}"
  retention_in_days = 14
}


# Task Security group
# ========================================================
resource "aws_security_group" "ecs-task-sg" {
  name        = "${var.ecs.service.name}-sg"
  description = "${var.ecs.service.name} security group"

  vpc_id = var.ecs.service.vpc_id

  dynamic "ingress" {
    for_each = toset([
      for container in var.ecs.task_definition.container_definitions : container.port
    ])
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.ecs.service.vpc_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.ecs.service.name}-sg"
  }
}
