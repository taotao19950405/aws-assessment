variable "test_email" {
  description = "email address for cognito test user and sns payload"
  type        = string
}

variable "github_repo" {
  description = "github repo url, used in sns payload"
  type        = string
}

variable "sns_topic_arn" {
  description = "sns topic arn for candidate verification"
  type        = string
  default     = "arn:aws:sns:us-east-1:637226132752:Candidate-Verification-Topic"
}