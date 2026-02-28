# AWS Multi-Region Infrastructure Assessment

A multi-region AWS infrastructure built with Terraform, featuring Cognito authentication, Lambda functions, ECS Fargate, API Gateway, and DynamoDB across `us-east-1` and `eu-west-1`.

## Architecture Overview

```
us-east-1 (primary)          eu-west-1 (secondary)
├── Cognito User Pool         ├── API Gateway (HTTP)
├── API Gateway (HTTP)        ├── Lambda - Greeter
├── Lambda - Greeter          ├── Lambda - Dispatcher
├── Lambda - Dispatcher       ├── ECS Fargate Cluster
├── ECS Fargate Cluster       └── DynamoDB Table
└── DynamoDB Table
```

### How Multi-Region Providers Work

Terraform uses [provider aliases](https://developer.hashicorp.com/terraform/language/providers/configuration#alias-multiple-provider-configurations) to deploy the same module into multiple regions simultaneously.

In `providers.tf`, two AWS provider configurations are defined:

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}
```

In `main.tf`, the same `compute` module is called twice, each time passing a different provider:

```hcl
module "compute_us_east_1" {
  source    = "./modules/compute"
  region    = "us-east-1"
  providers = { aws = aws.us_east_1 }
  ...
}

module "compute_eu_west_1" {
  source    = "./modules/compute"
  region    = "eu-west-1"
  providers = { aws = aws.eu_west_1 }
  ...
}
```

This ensures identical infrastructure is deployed in both regions from a single module definition.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.7.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [Node.js](https://nodejs.org/) >= 18.x
- AWS account with permissions for: Cognito, Lambda, ECS, API Gateway, DynamoDB, IAM, VPC, SNS

## Deployment

### 1. Clone the repository

```bash
git clone https://github.com/taotao19950405/aws-assessment.git
cd aws-assessment
```

### 2. Configure variables

Edit `terraform.tfvars`:

```hcl
test_email  = "your_email@example.com"
github_repo = "https://github.com/your-username/aws-assessment"
```

### 3. Initialize and deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
```

### 4. Note the outputs

```bash
terraform output
```

This will display:
- `cognito_user_pool_id`
- `cognito_client_id`
- `api_url_us_east_1`
- `api_url_eu_west_1`

## Running the Test Script

The test script authenticates with Cognito, then concurrently calls both `/greet` and `/dispatch` endpoints in both regions.

### Install dependencies

```bash
npm install @aws-sdk/client-cognito-identity-provider axios
```

### Run tests

```bash
TEST_PASSWORD='your_password' \
TEST_EMAIL='your_email@example.com' \
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id) \
CLIENT_ID=$(terraform output -raw cognito_client_id) \
API_URL_US=$(terraform output -raw api_url_us_east_1) \
API_URL_EU=$(terraform output -raw api_url_eu_west_1) \
node scripts/test.js
```

### What the test does

1. authenticates with Cognito to retrieve a JWT token
2. concurrently calls `/greet` in both `us-east-1` and `eu-west-1`
3. concurrently calls `/dispatch` in both regions to trigger ECS Fargate tasks
4. asserts that each response contains the correct region name
5. outputs latency measurements to demonstrate geographic performance difference

## CI/CD Pipeline

The GitHub Actions pipeline (`.github/workflows/deploy.yml`) runs automatically on push or PR to `main`:

| Job | Description |
|-----|-------------|
| **Lint & Validate** | runs `terraform fmt` and `terraform validate` |
| **Security Scan** | runs `tfsec` to check for security misconfigurations |
| **Plan** | generates a Terraform plan using AWS credentials from GitHub Secrets |
| **Deploy** | applies the plan on push to `main` only |
| **Test** | placeholder showing where the test script would run post-deployment |

## Tear Down

Once testing is complete, destroy all infrastructure to avoid charges:

```bash
terraform destroy
```
