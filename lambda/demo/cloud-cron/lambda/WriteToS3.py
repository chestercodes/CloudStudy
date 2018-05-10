import json, datetime

try:
    import boto3
    import botocore
except Exception as e:
    print("failed to import boto")
    pass

# Needs to be python 3.6

def write_file(bucket, key, obj):
    print("going to write file for real")
    client = boto3.client('s3')
    content = json.dumps(obj)
    client.put_object(Body=content, Bucket=bucket, Key=key)
    print("wrote file (?)")

def write_file_fake(bucket, key, contents):
    print("pretending to write file to bucket   - " + bucket)
    print("pretending to write file to key      - " + key)
    print("pretending to write file to contents - " + contents)

def handler_impl(event, context, writeFunc):
    bucket_name = event['bucket']

    file_path = f"{datetime.datetime.now():%Y_%m_%d_%H/%M_%S}" + ".txt"
    print("file path is " + file_path)
    
    writeFunc(bucket_name, file_path, "dummy contents")

def handler(event, context):
    print("WriteToS3 lambda called")
    handler_impl(event, context, write_file)
    print("WriteToS3 lambda finished")

# Manual invocation of the script (only used for testing)
if __name__ == "__main__":
    test = {}
    test["bucket"] = "my_bucket"
    
    handler_impl(test, None, write_file_fake)

