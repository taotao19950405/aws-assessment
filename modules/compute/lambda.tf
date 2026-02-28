# cloudwatch log groups for lambda
resource "aws_cloudwatch_log_group" "greeter" {
  name              = "/aws/lambda/${local.name_prefix}-greeter"
  retention_in_days = 3
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "dispatcher" {
  name              = "/aws/lambda/${local.name_prefix}-dispatcher"
  retention_in_days = 3
  tags              = local.common_tags
}

# zip greeter lambda source code
data "archive_file" "greeter" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/greeter"
  output_path = "${path.module}/lambda/greeter.zip"
}

# zip dispatcher lambda source code
data "archive_file" "dispatcher" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/dispatcher"
  output_path = "${path.module}/lambda/dispatcher.zip"
}

# greeter lambda, writes to dynamodb and publishes to sns
resource "aws_lambda_function" "greeter" {
  function_name    = "${local.name_prefix}-greeter"
  filename         = data.archive_file.greeter.output_path
  source_code_hash = data.archive_file.greeter.output_base64sha256
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 15

  environment {
    variables = {
      REGION         = var.region
      DYNAMODB_TABLE = aws_dynamodb_table.greeting_logs.name
      SNS_TOPIC_ARN  = var.sns_topic_arn
      TEST_EMAIL     = var.test_email
      GITHUB_REPO    = var.github_repo
    }
  }

  depends_on = [aws_cloudwatch_log_group.greeter]
  tags       = local.common_tags
}

# dispatcher lambda, triggers ecs fargate task
resource "aws_lambda_function" "dispatcher" {
  function_name    = "${local.name_prefix}-dispatcher"
  filename         = data.archive_file.dispatcher.output_path
  source_code_hash = data.archive_file.dispatcher.output_base64sha256
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 30

  environment {
    variables = {
      REGION            = var.region
      ECS_CLUSTER_ARN   = aws_ecs_cluster.main.arn
      TASK_DEF_ARN      = aws_ecs_task_definition.sns_publisher.arn
      SUBNET_IDS        = join(",", aws_subnet.public[*].id)
      SECURITY_GROUP_ID = aws_security_group.ecs_task.id
    }
  }

  depends_on = [aws_cloudwatch_log_group.dispatcher]
  tags       = local.common_tags
}