variable "test_email" {
  description = "Email address for the cognito test user"
  type        = string
}

variable "temp_password" {
  description = "Temporary password set during user creation"
  type        = string
  default     = "TempPass123!"
  sensitive   = true
}

variable "permanent_password" {
  description = "Permanent password confirmed via local-exec"
  type        = string
  default     = "PermanentPass123!"
  sensitive   = true
}