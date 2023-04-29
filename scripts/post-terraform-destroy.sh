#!/bin/bash

printf "Tearing down the AWS Aurora environment\n"

aws_terraform_path=${DEMO_PROJECT_ROOT}/aws &&
terraform -chdir=${aws_terraform_path} destroy -auto-approve &&
printf "Teardown complete\n"