# docstring
import json
import os
from s3path import S3Path

import boto3
client = boto3.client('s3') # example client, could be any
REGION = client.meta.region_name

import logging

# set up logger for CloudWatch
logger = logging.getLogger(__file__)
logger.setLevel(logging.DEBUG)


class Prefix(object):

    def __init__(self, uri):
        if isinstance(uri, S3Path):
            self.uri = uri.parent
        else:
            key = S3Path.from_uri(uri)
            self.uri = key.parent

    def __eq__(self, other):
        """Equality is tested by S3 key parent equality"""
        return (self.uri.parent == other.uri.parent)

    def __repr__(self):
        """Equality is tested by S3 key parent equality"""
        return repr(self.uri)



# {'messageId': '705be7c7-33de-47d0-a7bc-91f345e33348', 'receiptHandle': 'AQEB+EVpOv8HPOIBX6Yd3KERh8N33nUlxf7/ddH24645cH/wQbUvSpIzu6aTgBzbDqj5H1qeuLRy7Up1qLHV4G7lopkEJBKazBEkqJdjJ9TC9OYd8VS+sCYXZP9EPWP4nWkXN1GP56tdaPDefB7yj1X6BkPjQAANtPst+gPAnki4bM3bFFRTinjL5VxcRNm6C8YgQZFfIAdeVU3u7OfhDekUGtGauLQQeI+cxkaTMa6ABKl+l87+GL0Uhqh4oP4r9OVOLDFm7Ak/gpCYcTRtVIpxktJrYI/mm7mDda5Ihbs2XMzvPTikL/dNPiHuTkpyRZCn3jPLTFWxW/ZWxkxr2RDuZF2WA4YCrmqGZUTX/eDTRQLGMF2H3I//zaJl4IEPA09z', 'body': '{\n  "Type" : "Notification",\n  "MessageId" : "d689df28-6403-5b9a-8609-878b8b31f3ce",\n  "TopicArn" : "arn:aws:sns:us-east-1:259232244835:pips-dispatch",\n  "Message" : "{\\"bucket\\": \\"grid-dev-lidarscans\\", \\"key\\": \\"RiPS/jpg/hobu.jpg\\"}",\n  "Timestamp" : "2021-02-15T03:39:30.566Z",\n  "SignatureVersion" : "1",\n  "Signature" : "UZYKEnyYgjz3Nl3c0wmHBBTauwuDUlBY5LrtdPgf0ktoeT+LRA2bl/oKaO1ubCH8lwAZDr7zQor29R6VJsZbI6gWmC6Rv77QYpwV1g4FbUX7HJcgVEm42U76Nq8zcF//09jEtY7qIvEmvSzr1MAa3tk1IerFHCXmEULF46tnUo5RbH1viabGu/kmI6k7Rah6zT+7WT3mqT+9g5ID85YvovDLhOaCrlxsg+aePzbb1CtPohpbdeRfI4PsGqqxGRL/uLA3PxCPPlYDSIqPgijK8LNY8+ZfPgaMpsQAUd2O0TyXqfiwE6zoTylkxTsMnHPEUXb/WkOjwrHJcT4VHoLS5Q==",\n  "SigningCertURL" : "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-010a507c1833636cd94bdb98bd93083a.pem",\n  "UnsubscribeURL" : "https://sns.us-east-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:us-east-1:259232244835:pips-dispatch:bf355acc-8839-48ba-8426-9f62a3ab9730",\n  "MessageAttributes" : {\n    "Command" : {"Type":"String","Value":"process"},\n    "Prefix" : {"Type":"String","Value":"/grid-dev-lidarscans/RiPS/jpg"}\n  }\n}', 'attributes': {'ApproximateReceiveCount': '1', 'SentTimestamp': '1613360370611', 'SenderId': 'AIDAIT2UOQQY3AUEKVGXU', 'ApproximateFirstReceiveTimestamp': '1613360370615'}, 'messageAttributes': {}, 'md5OfBody': '2eac0c6b3151018833816d501204e42d', 'eventSource': 'aws:sqs', 'eventSourceARN': 'arn:aws:sqs:us-east-1:259232244835:pips-tasks', 'awsRegion': 'us-east-1'}

def extract_records(records):

    keys = []
    prefixes = []

    for record in records:

        handle = None
        if 'receiptHandle' in record:
            handle = record['receiptHandle']

        logger.debug(f"message {record}")

        if record['eventSource'] == 'aws:sqs':
            # pipeline comes through record['body'] as text
            body = json.loads(record['body'])
            logger.debug(f"body {body}")
            message = json.loads(body['Message'])
            logger.debug(f"message {message}")
            bucket = message['bucket']
            key = message['key'].strip('/')

        if record['eventSource'] == 'aws:sns':
            # pipeline comes through record['body'] as text
            message = json.loads(record['message'])
            bucket = message['bucket']
            key = message['key'].strip('/')

        elif record['eventSource'] == 'aws:s3':

            # pipeline is the bucket/key
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']

        key = key.lstrip('/')
        uri = os.path.join('s3://', bucket, key)
        key = S3Path.from_uri(uri)

        prefix = Prefix(key)

        if prefix not in prefixes:
            prefixes.append(prefix)

        return prefixes


def get_job_info(context):
    arn = context.invoked_function_arn

    aws_lambda = boto3.client('lambda')
    tags = aws_lambda.list_tags(Resource = arn)
    stage = tags['Tags']['STAGE']
    stack = tags['Tags']['name']

    output = {}
    output['queue'] = f'{stack}-{stage}-jobqueue'
    output['definition'] = f'{stack}-{stage}-job'

    return output




def dispatch(event, context):
    """ Dispatches a Batch job for the given S3 prefixes """

    logger.debug("'dispatch' handler called")
    logger.debug(event)

    import boto3

    prefixes = extract_records(event['Records'])
    logger.debug(f'prefixes {prefixes}')

    batch = boto3.client(
        service_name='batch',
        region_name=f'{REGION}',
        endpoint_url=f'https://batch.{REGION}.amazonaws.com')


    info = get_job_info(context)
    logger.debug(f'submitting job {info}')

    for prefix in prefixes:

        logger.debug(f'submitting job for prefix {prefix}')
        jobName = prefix.uri.stem
        parameters = {"bucketname":prefix.uri.bucket,
                      "collectname":jobName,
                      "outputname":'output'}

        submitJobResponse = batch.submit_job(
            jobName=jobName,
            jobQueue=info['queue'],
            jobDefinition=info['definition'],
            parameters=parameters,
            retryStrategy = {'attempts':1},
            timeout = {'attemptDurationSeconds': 1 * 24*60*60}
        )


def cancel(event, context):
    """ Cancels a Batch job for the given S3 prefixes """

    logger.debug("'cancels' handler called")
    logger.debug(event)

    import boto3

    prefixes = extract_records(event['Records'])
    logger.debug(f'prefixes {prefixes}')

    batch = boto3.client(
        service_name='batch',
        region_name=f'{REGION}',
        endpoint_url=f'https://batch.{REGION}.amazonaws.com')

    statuses = ['SUBMITTED', 'PENDING', 'RUNNABLE','STARTING','RUNNING']

    info = get_job_info(context)
    logger.debug(f'submitting job {info}')

    for prefix in prefixes:
        for status in statuses:
            jobs = batch.list_jobs(jobQueue = info['queue'],
                                   jobStatus=status)
            for job in jobs['jobSummaryList']:

                if job['jobName'] == prefix.uri.stem:
                    # kill it
                    logger.debug(job)
                    response = batch.terminate_job(jobId = job['jobId'], reason='Canceled by user copying sentinel file')
                    logger.debug(response)


