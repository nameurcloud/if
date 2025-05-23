# Project Name
nameurcloud - Infra 
## Description
This is the repo holding terraform code to build and maintain nameurcloud infrastructure

## Requirements
- Terraform (v1.11.3 or higher)
- Service Account Key  ( Get it from the owner if you want to run locally )

## Running the Project Locally

### Step 1: Configure Secret
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your-service-account-key.json"

### Step 2: Update tfvars
Update Project. DO NOT USE PRODUCTION

```bash
terraform init
terraform plan
terraform apply

