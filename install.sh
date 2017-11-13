#!/bin/bash

set -e

ZIP_FILE=lambda.zip

STACK_NAME=summer-of-s3

bucket=$1
if [ -z $bucket ]; then
    read -p "S3 bucket to store template assets (e.g. mybucket): " bucket
fi

echo "Packaging code..."

./package.sh

echo "Deploying application"

# Use existing bucket if we've deployed before
bucket_name=$(aws cloudformation describe-stacks --stack-name $STACK_NAME 2>/dev/null | jq -r .Stacks[0].Outputs[0].OutputValue)
if [ -z $bucket_name ]; then
    bucket_name=${STACK_NAME}-$(pwgen -A -0 8 1)
fi

# Do the deployment
aws cloudformation package --template-file template.yaml --s3-bucket $bucket --output-template-file template.out.yaml >/dev/null
aws cloudformation deploy --template-file template.out.yaml --stack-name $STACK_NAME --parameter-overrides BucketName=$bucket_name --capabilities CAPABILITY_IAM >/dev/null

# Clean up
rm $ZIP_FILE
rm template.out.yaml

outputs=$(aws cloudformation describe-stacks --stack-name $STACK_NAME | jq '.Stacks[0].Outputs | map({key: .OutputKey, value: .OutputValue}) | from_entries')
bucket=$(echo $outputs | jq -r .BucketName)
website=$(echo $outputs | jq -r .Website)

echo "Uploading a test file to the bucket..."

# Test
aws s3 cp --acl public-read README.md s3://$bucket >/dev/null
echo

# Finished
echo "The bucket is: $bucket"
echo "The website is at: $website"
