terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# create cognito user pool
resource "aws_cognito_user_pool" "main" {
  name = "unleash-live-user-pool"

  # use alias_attributes instead if both email and username allowed to login
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # password policies
  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  # use email to recover account when password is foggoten 
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Project = "unleash-live-assessment"
  }
}

# create app client, which authenticate test script by email and password
resource "aws_cognito_user_pool_client" "main" {
  name         = "unleash-live-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # test cognito connection by script, no server to store secret
  generate_secret = false

  #  ALLOW_USER_SRP_AUTH and ALLOW_REFRESH_TOKEN_AUTH can be used when needed
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH"
  ]
}

# create test user
resource "aws_cognito_user" "test" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = var.test_email

  temporary_password = var.temp_password
  message_action     = "SUPPRESS"

  attributes = {
    email          = var.test_email
    email_verified = "true"
  }
}

# cognito requires changing password for first time login， otherwise returns error new_password_required
# set password in test script to be permanent to bypass cognito for the first time
resource "null_resource" "confirm_test_user" {
  depends_on = [aws_cognito_user.test]

  #EOT means the content in between are all commands
  provisioner "local-exec" {
    command = <<-EOT
      aws cognito-idp admin-set-user-password \
        --user-pool-id ${aws_cognito_user_pool.main.id} \
        --username ${var.test_email} \
        --password '${var.permanent_password}' \
        --permanent \
        --region us-east-1
    EOT
  }
}