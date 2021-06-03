#!/bin/bash

set -e

STACK_NAME="$1"
if [ -z "$STACK_NAME" ]
then
      echo "STACK_NAME is empty, you must set one to use this script"
      exit 1;
fi

echo "Stack name: $STACK_NAME"
AWS_AMI=$(aws ssm get-parameter --name /aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended --region $AWS_DEFAULT_REGION --output json |jq -r .Parameter.Value|jq -r .image_id)

export AWS_IDENTITY=$(aws sts get-caller-identity --query 'Account' --output text)
echo "AWS Identity: $AWS_IDENTITY"

STAGE=$( aws cloudformation describe-stacks --stack-name $STACK_NAME |jq -r '.Stacks[] | select (.StackName == "'$STACK_NAME'").Tags[] | select (.Key == "STAGE").Value' )
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
echo "did we find ECR_REPONAME: $ECR_REPONAME"

# If we don't have ECR, we probably don't have the ssh key either.
# Try to create it.
if [[ "$ECR_REPONAME" != "$CONTAINER_NAME" ]]; then
    echo "Creating ECR repository $CONTAINER_NAME"
    aws ecr create-repository --repository-name $CONTAINER_NAME \
        --tags "Key=Name,Value=$STACK_NAME:ecr.$STAGE"
fi



docker build -t $AWS_IDENTITY.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/${CONTAINER_NAME} .
docker push $AWS_IDENTITY.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/${CONTAINER_NAME}

IMG_SHA=$(aws ecr describe-images --repository-name $CONTAINER_NAME --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageDigest' --output json |jq -r)

IMAGE_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$CONTAINER_NAME@$IMG_SHA

echo "Image SHA: $IMG_SHA"
echo "Image URI: $IMAGE_URI"

aws s3 cp settings.yaml s3://$STACK_NAME-$STAGE-codm/settings.yaml

# aws lambda update-function-code \
#     --function-name "$STACK_NAME-$STAGE-dispatch" \
#     --image-uri $IMAGE_URI
#
# aws lambda update-function-code \
#     --function-name "$STACK_NAME-$STAGE-cancel" \
#     --image-uri $IMAGE_URI
