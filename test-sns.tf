# set to 1 to deploy test sns topic, 0 to skip
variable "deploy_test_sns" {
  description = "set to 1 to create a test sns topic for local testing"
  type        = number
  default     = 0
}

resource "aws_sns_topic" "test" {
  count = var.deploy_test_sns
  name  = "MyTestTopic"
  tags  = { Project = "unleash-live-assessment" }

  provider = aws.us_east_1
}

resource "aws_sns_topic_subscription" "test_email" {
  count     = var.deploy_test_sns
  topic_arn = aws_sns_topic.test[0].arn
  protocol  = "email"
  endpoint  = var.test_email

  provider = aws.us_east_1
}

output "test_sns_arn" {
  value = var.deploy_test_sns == 1 ? aws_sns_topic.test[0].arn : "not deployed"
}


# add iam policy only for testing when deploy_test_sns = 1, when its not test we do not want this sns topic open to the role
# allow ecs task roles to publish to test topic when testing
resource "aws_iam_role_policy" "ecs_test_sns_us" {
  count = var.deploy_test_sns
  name  = "test-sns-publish-us"
  role  = "unleash-us-east-1-ecs-task-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.test[0].arn
    }]
  })

  provider = aws.us_east_1
}

resource "aws_iam_role_policy" "ecs_test_sns_eu" {
  count = var.deploy_test_sns
  name  = "test-sns-publish-eu"
  role  = "unleash-eu-west-1-ecs-task-role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.test[0].arn
    }]
  })

  provider = aws.us_east_1
}

# allow lambda roles to publish to test topic when testing
resource "aws_iam_role_policy" "lambda_test_sns_us" {
  count = var.deploy_test_sns
  name  = "test-sns-publish-lambda-us"
  role  = "unleash-us-east-1-lambda-exec"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.test[0].arn
    }]
  })

  provider = aws.us_east_1
}

resource "aws_iam_role_policy" "lambda_test_sns_eu" {
  count = var.deploy_test_sns
  name  = "test-sns-publish-lambda-eu"
  role  = "unleash-eu-west-1-lambda-exec"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.test[0].arn
    }]
  })

  provider = aws.us_east_1
}