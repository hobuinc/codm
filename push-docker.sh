#!/bin/bash

set -e

PREFIX=$(cat terraform.tfstate | jq '.outputs.prefix.value // empty' -r)
STAGE=$(cat terraform.tfstate | jq '.outputs.stage.value // empty' -r)


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


export AWS_IDENTITY=$(aws sts get-caller-identity --query 'Account' --output text)
echo "AWS Identity: $AWS_IDENTITY"



aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login -u AWS --password-stdin "https://$AWS_IDENTITY.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"

CONTAINER_NAME="$PREFIX-$STAGE-codm"
echo "Container name: $CONTAINER_NAME"

ECR_REPONAME=$(aws ecr describe-repositories |jq -r '.repositories[] | select (.repositoryName == "'$CONTAINER_NAME'").repositoryName')
echo "did we find ECR_REPONAME: $ECR_REPONAME"



docker build --platform linux/amd64 -t $AWS_IDENTITY.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/${CONTAINER_NAME}:latest .
docker push $AWS_IDENTITY.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/${CONTAINER_NAME}:latest

IMG_SHA=$(aws ecr describe-images --repository-name $CONTAINER_NAME --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageDigest' --output json |jq -r)

IMAGE_URI=$AWS_IDENTITY.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$CONTAINER_NAME@$IMG_SHA

echo "Image SHA: $IMG_SHA"
echo "Image URI: $IMAGE_URI"

