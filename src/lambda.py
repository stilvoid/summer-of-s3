"""
summer-of-s3
"""

import boto3
import hashlib

client = boto3.client("s3")

INDEX = "index.html"

def user_error(message):
    return {
        "statusCode": 400,
        "body": message,
    }

def put_checksums(bucket, key):
    obj = client.get_object(Bucket=bucket, Key=key)

    data = obj["Body"].read()

    md5 = hashlib.md5()
    md5.update(data)
    client.put_object(
        Bucket=bucket,
        Key="{}.md5.txt".format(key),
        ContentType="text/plain",
        ContentDisposition="inline",
        ACL="public-read",
        Body=md5.hexdigest()
    )

    sha1 = hashlib.sha1()
    sha1.update(data)
    client.put_object(
        Bucket=bucket,
        Key="{}.sha1.txt".format(key),
        ContentType="text/plain",
        ContentDisposition="inline",
        ACL="public-read",
        Body=sha1.hexdigest()
    )

def build_index(bucket):
    paginator = client.get_paginator("list_objects_v2")

    keys = sorted([
        obj["Key"]
        for page in paginator.paginate(Bucket=bucket)
        for obj in page["Contents"]
        if obj["Key"] != INDEX
    ])

    index = """<!DOCTYPE html>
<html lang="en">
    <head><title>List of objects in {bucket}</title></head>
    <body>
        <h1>List of objects in {bucket}</h1>
        <ul>{object_list}</ul>
    </body>
</html>""".format(bucket=bucket, object_list="".join([
    "<li><a href=\"/{key}\">{key}</a></li>".format(key=key)
    for key in keys
]))

    client.put_object(
        Bucket=bucket,
        Key=INDEX,
        ContentType="text/html",
        ContentDisposition="inline",
        ACL="public-read",
        Body=index,
    )

def handler(event, context):
    buckets = set()

    for record in event["Records"]:
        key = record["s3"]["object"]["key"]

        bucket_name = record["s3"]["bucket"]["name"]
        buckets.add(bucket_name)

        if key.endswith(".md5.txt") or key.endswith(".sha1.txt") or key == INDEX:
            print("Ignoring {}".format(key))
            continue

        if record["eventName"].startswith("ObjectCreated"):
            put_checksums(bucket_name, key)

    for bucket in buckets:
        build_index(bucket)
