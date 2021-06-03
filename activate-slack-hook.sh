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


LAMBDA_NAME="$STACK_NAME-$STAGE-notify"
echo "Lambda name: $LAMBDA_NAME"

LAMBDA_ARN=$(aws lambda get-function --function-name $LAMBDA_NAME |jq -r .Configuration.FunctionArn)
echo "Lambda ARN: $LAMBDA_ARN"

if [ -z "$LAMBDA_ARN" ]
then
      echo "LAMBDA_ARN is empty. Cannot set slack hook"
      exit 1;
fi

SLACK_URL=$(cat slack-url.txt)

echo $SLACK_URL

TAGIT=$(aws lambda tag-resource --resource $LAMBDA_ARN --tags slackhook=$SLACK_URL)
