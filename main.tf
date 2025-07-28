provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Read task definition JSON files
data "local_file" "task_def1" {
  filename = "td1.json"
}

data "local_file" "task_def2" {
  filename = "td2.json"
}

# Parse JSON into Terraform locals
locals {
  td1 = jsondecode(data.local_file.task_def1.content)
  td2 = jsondecode(data.local_file.task_def2.content)
}

# Security group
resource "aws_security_group" "ecs_service" {
  name        = "ecs-service-sg"
  description = "Allow HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "abhishekharkar-ecs-cluster"
  depends_on = [aws_iam_role.ecs_task_execution_role, aws_iam_role_policy_attachment.ecs_task_execution_role_policy]
}

# Task Definitions from JSON
resource "aws_ecs_task_definition" "from_file1" {
  family                   = local.td1.family
  network_mode             = local.td1.networkMode
  requires_compatibilities = local.td1.requiresCompatibilities
  cpu                      = local.td1.cpu
  memory                   = local.td1.memory
  container_definitions    = jsonencode(local.td1.containerDefinitions)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_ecs_task_definition" "from_file2" {
  family                   = local.td2.family
  network_mode             = local.td2.networkMode
  requires_compatibilities = local.td2.requiresCompatibilities
  cpu                      = local.td2.cpu
  memory                   = local.td2.memory
  container_definitions    = jsonencode(local.td2.containerDefinitions)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

# ECS Services
resource "aws_ecs_service" "main1" {
  name            = "api-with-redis-service"
  cluster         = aws_ecs_cluster.main.id
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.from_file1.arn

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service.id]
  }

  depends_on = [aws_ecs_task_definition.from_file1]
}

resource "aws_ecs_service" "main2" {
  name            = "frontend-service"
  cluster         = aws_ecs_cluster.main.id
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.from_file2.arn

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_service.id]
  }

  depends_on = [ aws_ecs_task_definition.from_file2]
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
