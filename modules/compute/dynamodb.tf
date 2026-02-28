# regional dynamodb table, each region has its own table
resource "aws_dynamodb_table" "greeting_logs" {
  name         = "GreetingLogs-${var.region}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # encrypt data at rest
  server_side_encryption {
    enabled = true
  }

  tags = local.common_tags
}