#!/bin/bash

STACK_NAME=summer-of-s3

outputs=$(aws cloudformation describe-stacks --stack-name $STACK_NAME | jq '.Stacks[0].Outputs | map({key: .OutputKey, value: .OutputValue}) | from_entries')
bucket=$(echo $outputs | jq -r .BucketName)

echo "Emptying the bucket"
aws s3 rm --recursive s3://$bucket/

echo "Uninstalling the application"
aws cloudformation delete-stack --stack-name $STACK_NAME
