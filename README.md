# summer-of-s3

A serverless application that generates md5 and sha1 checksums for files uploaded to an S3 bucket allowing you to easily manage a website of downloads. summer-of-s3 also generates an index document for you that lists all of the files present in your bucket.

## Installing

Run the `install.sh` script to create an S3 bucket and configure it for use with summer-of-s3.

If you make any changes, deploy them with `update.sh`.

## Uninstalling

You can either remove the S3 bucket contents yourself and then delete the CloudFormation stack or run the `uninstall.sh` script which does that for you.
