# api gateway url for this region
output "api_url" {
  value = aws_apigatewayv2_api.main.api_endpoint
}

# dynamodb table name for this region
output "dynamodb_table_name" {
  value = aws_dynamodb_table.greeting_logs.name
}

# ecs cluster arn for this region
output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}