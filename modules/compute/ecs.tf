# ecs cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = local.common_tags
}

# cloudwatch log group for ecs task
resource "aws_cloudwatch_log_group" "ecs_task" {
  name              = "/ecs/${local.name_prefix}-sns-publisher"
  retention_in_days = 3
  tags              = local.common_tags
}

# ecs task definition, uses aws-cli to publish to sns then exits
resource "aws_ecs_task_definition" "sns_publisher" {
  family                   = "${local.name_prefix}-sns-publisher"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "sns-publisher"
    image = "amazon/aws-cli:latest"
    # publish sns message then exit
    command = [
      "sns", "publish",
      "--topic-arn", var.sns_topic_arn,
      "--message", "{\"email\":\"${var.test_email}\",\"source\":\"ECS\",\"region\":\"${var.region}\",\"repo\":\"${var.github_repo}\"}",
      "--region", "us-east-1"
    ]
    essential = true
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${local.name_prefix}-sns-publisher"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = local.common_tags
}