#!/bin/bash

printf "*************************************\n"
printf "Setting up the AWS EC2 instance for Wordle - Terraform init\n"
# setup the AWS environment
aws_terraform_path=${DEMO_PROJECT_ROOT}/aws/terraform &&
terraform -chdir=${aws_terraform_path} init &&
printf "Setting up the AWS Aurora environment - Terraform apply\n"
printf "This will take a while...\n"
terraform -chdir=${aws_terraform_path} apply -auto-approve

#store the AWS endpoint in the .env file
instance_dns=$(terraform -chdir=${aws_terraform_path} output -raw 'instance_dns')
printf $instance_dns
replace_env_vars AWS_MYSQL_HOST AWS_INSTANCE_DNS=${instance_dns}

printf "AWS EC2 setup complete\n"
printf "*************************************\n\n"