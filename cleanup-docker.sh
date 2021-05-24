#!/bin/bash

set -e

STACK_NAME="$1"
if [ -z "$STACK_NAME" ]
then
      echo "STACK_NAME is empty, you must set one to use this script"
      exit 1;
fi

echo "Stack name: $STACK_NAME"

export AWS_IDENTITY=$(aws sts get-caller-identity --query 'Account' --output text)
echo "AWS Identity: $AWS_IDENTITY"

STAGE=$( aws cloudformation describe-stacks --stack-name codm2|jq -r '.Stacks[] | select (.StackName == "'$STACK_NAME'").Tags[] | select (.Key == "STAGE").Value' )
STACK_ID=$( aws cloudformation list-stacks --stack-status-filter UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE  |jq '.StackSummaries[] | select(.StackName == "'$STACK_NAME'").StackId' -r)


if [ -z "$STAGE" ]
then
      echo "STAGE is empty. Is the Cloud Formation Stack created?"
      exit 1;
fi

if [ -z "$STACK_ID" ]
then
      echo "STACK_ID is empty. Is the Cloud Formation stack valid?"
      exit 1;
fi

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login -u AWS --password-stdin "https://$AWS_IDENTITY.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"

CONTAINER_NAME="$STACK_NAME-$STAGE-codm"
echo "Container name: $CONTAINER_NAME"

ECR_REPONAME=$(aws ecr describe-repositories |jq -r '.repositories[] | select (.repositoryName == "'$CONTAINER_NAME'").repositoryName')
echo "ECR_REPONAME: $ECR_REPONAME"



SHAS=$(aws ecr describe-images --repository-name $CONTAINER_NAME --query 'sort_by(imageDetails,& imagePushedAt)' --output json |jq -r '.[].imageDigest')


for DIGEST in $SHAS;
do
    aws ecr batch-delete-image --repository-name $CONTAINER_NAME --image-ids imageDigest=$DIGEST
done;

aws rm --recursive s3://$STACK_NAME-$STAGE-codm/

