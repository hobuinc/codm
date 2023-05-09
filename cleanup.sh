#!/bin/bash

set -e

rm -rf builds
rm -rf lambda-*

BUCKET=$(cat terraform.tfstate | jq '.outputs.bucket.value // empty' -r)
PREFIX=$(cat terraform.tfstate | jq '.outputs.prefix.value // empty' -r)
STAGE=$(cat terraform.tfstate | jq '.outputs.stage.value // empty' -r)

if [ -z "$BUCKET" ]
then
      echo "BUCKET value is empty, unable to fetch from terraform.tfstate"
      exit 1;
fi

if [ -z "$PREFIX" ]
then
      echo "PREFIX is empty, unable to fetch from terraform.tfstate"
      exit 1;
fi

if [ -z "$STAGE" ]
then
      echo "STAGE is empty, unable to fetch from terraform.tfstate"
      exit 1;
fi
echo "wiping up $BUCKET bucket"
aws s3 rm "s3://$BUCKET" --recursive
rm -rf drone_dataset_brighton_beach-master


export AWS_IDENTITY=$(aws sts get-caller-identity --query 'Account' --output text)
echo "AWS Identity: $AWS_IDENTITY"

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login -u AWS --password-stdin "https://$AWS_IDENTITY.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"

CONTAINER_NAME="$PREFIX-$STAGE-codm"
echo "Container name: $CONTAINER_NAME"

ECR_REPONAME=$(aws ecr describe-repositories |jq -r '.repositories[] | select (.repositoryName == "'$CONTAINER_NAME'").repositoryName')
echo "ECR_REPONAME: $ECR_REPONAME"

SHAS=$(aws ecr describe-images --repository-name $CONTAINER_NAME --query 'sort_by(imageDetails,& imagePushedAt)' --output json |jq -r '.[].imageDigest')

echo "ECR Images: $SHAS"

for DIGEST in $SHAS;
do
    aws ecr batch-delete-image --repository-name $CONTAINER_NAME --image-ids imageDigest=$DIGEST
done;


