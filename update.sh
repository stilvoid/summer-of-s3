#!/bin/bash

set -e

STACK_NAME=summer-of-s3

echo "Packaging code..."

# Create a bucket
temp_bucket=${STACK_NAME}-$(pwgen -A -0 8 1)
aws s3 mb s3://$temp_bucket >/dev/null

echo "Deploying application"

# Do the sam deployment
bucket_name=${STACK_NAME}-$(pwgen -A -0 8 1)
sam package --template-file template.yaml --s3-bucket $temp_bucket --output-template-file template.out.yaml >/dev/null
sam deploy --template-file template.out.yaml --stack-name $STACK_NAME --capabilities CAPABILITY_IAM >/dev/null

# Clean up
aws s3 rm --recursive s3://$temp_bucket >/dev/null
aws s3 rb s3://$temp_bucket >/dev/null
rm template.out.yaml

outputs=$(aws cloudformation describe-stacks --stack-name $STACK_NAME | jq '.Stacks[0].Outputs | map({key: .OutputKey, value: .OutputValue}) | from_entries')
bucket=$(echo $outputs | jq -r .BucketName)
website=$(echo $outputs | jq -r .Website)

echo "The bucket is $bucket"
echo "The website is at $website"
