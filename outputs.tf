output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_client_id" {
  value = module.cognito.client_id
}

output "api_url_us_east_1" {
  value = module.compute_us_east_1.api_url
}

output "api_url_eu_west_1" {
  value = module.compute_eu_west_1.api_url
}