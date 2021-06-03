#!/bin/bash

set -e


echo "Region: $AWS_DEFAULT_REGION"

if [ -z "$AWS_DEFAULT_REGION" ]
then
      echo "AWS_DEFAULT_REGION is empty. Are your AWS variables set?"
      exit 1;
fi

AWS_AMI=$(aws ssm get-parameter --name /aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended --region $AWS_DEFAULT_REGION --output json |jq -r .Parameter.Value|jq -r .image_id)

rm -rf ami.yaml
echo "$AWS_AMI" >> ami.yaml
echo "CODM GPU AMI: $AWS_AMI"

export AWS_IDENTITY=$(aws sts get-caller-identity --query 'Account' --output text)
echo "AWS Identity: $AWS_IDENTITY"

SUBNETS=$(aws ec2 describe-subnets|jq -r '.Subnets[].SubnetId')

rm -rf subnets.yaml
for SUBNET in $SUBNETS
do

    echo "- $SUBNET" >> subnets.yaml
done

rm -rf security-groups.yaml
SECURITY_GROUPS=$(aws ec2 describe-security-groups --group-names 'default'|jq -r '.SecurityGroups[0].GroupId')
for SECURITY_GROUP in $SECURITY_GROUPS
do

    echo "- $SECURITY_GROUP" >> security-groups.yaml
done
