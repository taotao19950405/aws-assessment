variable "region" {
  description = "aws region this module is deployed to"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "arn of the cognito user pool in us-east-1"
  type        = string
}

variable "cognito_user_pool_id" {
  description = "id of the cognito user pool in us-east-1"
  type        = string
}

variable "cognito_client_id" {
  description = "cognito app client id"
  type        = string
}

variable "sns_topic_arn" {
  description = "unleash live sns topic arn for candidate verification"
  type        = string
}

variable "test_email" {
  description = "candidate email, used in sns payload"
  type        = string
}

variable "github_repo" {
  description = "github repo url, used in sns payload"
  type        = string
}