#!/bin/bash

set -e


echo "Region: $AWS_DEFAULT_REGION"

if [ -z "$AWS_DEFAULT_REGION" ]
then
      echo "AWS_DEFAULT_REGION is empty. Are your AWS variables set?"
      exit 1;
fi

AWS_AMI=$(aws ssm get-parameter --name /aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended --region $AWS_DEFAULT_REGION --output json |jq -r .Parameter.Value|jq -r .image_id)

echo "CODM GPU AMI: $AWS_AMI"

export AWS_IDENTITY=$(aws sts get-caller-identity --query 'Account' --output text)
echo "AWS Identity: $AWS_IDENTITY"
