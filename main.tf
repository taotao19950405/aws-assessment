terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# centralised cognito in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# secondary region
provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

module "cognito" {
  source     = "./cognito"
  test_email = var.test_email

  providers = {
    aws = aws.us_east_1
  }
}

# compute stack in us-east-1
module "compute_us_east_1" {
  source = "./modules/compute"

  region                = "us-east-1"
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_client_id     = module.cognito.client_id
  sns_topic_arn         = var.sns_topic_arn
  test_email            = var.test_email
  github_repo           = var.github_repo

  providers = {
    aws = aws.us_east_1
  }
}

# compute stack in eu-west-1
module "compute_eu_west_1" {
  source = "./modules/compute"

  region                = "eu-west-1"
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_client_id     = module.cognito.client_id
  sns_topic_arn         = var.sns_topic_arn
  test_email            = var.test_email
  github_repo           = var.github_repo

  providers = {
    aws = aws.eu_west_1
  }
}