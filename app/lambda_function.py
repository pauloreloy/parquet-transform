import boto3
import io
import os
import boto3.exceptions
import secrets
import pandas as pd
import awswrangler as wr
from datetime import datetime, timedelta

s3_client = boto3.client('s3')

def get_bucket_name():
    env = os.environ.get('ENVIRONMENT', 'dev')
    bucket_name = os.environ.get('S3_BUCKET', 'retencaobucket')
    bucket_name = f'{bucket_name}-{env}'
    return bucket_name

def generate_random_hex_string(length=32):
    return ''.join(secrets.choice('0123456789abcdef') for _ in range(length))

def get_bucket_prefix():
    env = os.environ.get('ENVIRONMENT', 'dev')
    prefix_name = os.environ.get('S3_FOLDER', 'processed/lake/')
    return prefix_name

def get_time():
    utc_now = datetime.utcnow()
    utc_minus_3 = utc_now + timedelta(hours=-3)
    time = utc_minus_3.isoformat()
    return time

def parse_dynamodb_image(image):
    parsed_data = {}
    for key, value in image.items():
        parsed_data[key] = parse_dynamodb_value(value)
    return parsed_data

def parse_dynamodb_value(value):
    if 'S' in value:
        return value['S']  # String
    elif 'N' in value:
        return value['N']  # Number (assuming it's a string representation)
    elif 'BOOL' in value:
        return value['BOOL']  # Boolean
    elif 'M' in value:
        return parse_dynamodb_image(value['M'])  # Nested Map (recursive call)
    elif 'L' in value:
        return [parse_dynamodb_value(item) for item in value['L']]  # List
    else:
        raise ValueError(f"Unsupported DynamoDB value type: {value}")
    
def lambda_handler(event, context):
    for record in event['Records']:
        if record['eventName'] == 'INSERT':
            handle_insert(record)
        elif record['eventName'] == 'MODIFY':
            handle_modify(record)
        elif record['eventName'] == 'REMOVE':
            handle_remove(record)

def handle_insert(record):
    new_image = record['dynamodb']['NewImage']
    portability_data = parse_dynamodb_image(new_image)
    store_to_s3('INSERT', portability_data)

def handle_modify(record):
    new_image = record['dynamodb']['NewImage']
    portability_data = parse_dynamodb_image(new_image)
    store_to_s3('MODIFY', portability_data)

def handle_remove(record):
    old_image = record['dynamodb']['OldImage']
    portability_data = parse_dynamodb_image(old_image)
    store_to_s3('REMOVE', portability_data)

def store_to_s3(event_type, portability_data):
    timestamp = get_time()
    now = datetime.now() + timedelta(hours=-3)
    s3_key = f"s3://{get_bucket_name()}/{get_bucket_prefix()}"
    data = {
        'eventType': event_type,
        'timestamp': timestamp,
        'year': str(now.year),
        "month": str(f"{now.month:02d}"),
        "day": str(f"{now.day:02d}"),
        'data': portability_data
    }
    df = pd.DataFrame(data)
    wr.s3.to_parquet(
        df=df,
        path=s3_key,
        dataset=True,
        mode="append",
        partition_cols=["year", "month", "day"],
    )