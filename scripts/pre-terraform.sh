#!/bin/bash

printf "*************************************\n"
printf "Setting up the AWS Aurora environment - Terraform init\n"
# setup the AWS environment
aws_terraform_path=${DEMO_PROJECT_ROOT}/aws &&
terraform -chdir=${aws_terraform_path} init &&
printf "Setting up the AWS Aurora environment - Terraform apply\n"
printf "This will take a while...\n"
terraform -chdir=${aws_terraform_path} apply -auto-approve

#store the AWS endpoint in the .env file
cluster_endpoint=$(terraform -chdir=${aws_terraform_path} output -raw 'cluster_endpoint')
printf $cluster_endpoint
replace_env_vars AWS_MYSQL_HOST AWS_MYSQL_HOST=${cluster_endpoint}

printf "AWS Aurora setup complete\n"
printf "*************************************\n\n"