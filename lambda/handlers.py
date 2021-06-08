# docstring
import json
import os
from s3path import S3Path
import requests
import yaml

import boto3
from botocore.exceptions import ClientError

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

    try:
        slack = tags['Tags']['slackhook']
    except KeyError:
        slack = None

    try:
        sesdomain = tags['Tags']['sesdomain']
    except KeyError:
        sesdomain = None

    try:
        sesregion = tags['Tags']['sesregion']
    except KeyError:
        sesregion = None


    output = {}
    output['queue'] = f'{stack}-{stage}-jobqueue'
    output['definition'] = f'{stack}-{stage}-job'
    output['sns'] = f'{stack}-{stage}-notifications'
    output['stage'] = f'{stage}'
    output['stack'] = f'{stack}'
    output['slack'] = slack
    output['sesregion'] = sesregion
    output['sesdomain'] = sesdomain

    return output


def notify_slack(slack_url, event, context):
    info = get_job_info(context)
    logger.debug(f'notify_slack for job {info}')


    logger.debug(f'notifying slack for context {context}')
    logger.debug(f'notifying slack for context {event}')
    message = event
    status = message['detail']['status']
    bucket = message['detail']['parameters']['bucketname']
    collect = message['detail']['parameters']['collectname']
    prefix = f's3://{bucket}/{collect}/'

    if status == 'FAILED':
        color = 'danger'
    else:
        color = 'good'

    text = f"""CODM Processing Task Status for {collect} \n
```{prefix}```"""

    fallback_message = text
    pretext = text
    template ={
        "fallback": f"{fallback_message}",
        "pretext": f"{pretext}",
        "color": f"{color}",

        "fields": [
            {
                "title": "Status",
                "value": f"{status}"
            }
        ]
    }

    r = requests.post(slack_url, json=template)
    logger.debug(f'notify_slack hook post {r.status_code}')


def notify_email(addresses, event, context):

    message = event
    status = message['detail']['status']
    bucket = message['detail']['parameters']['bucketname']
    collect = message['detail']['parameters']['collectname']
    prefix = f's3://{bucket}/{collect}/'

    if status == 'FAILED':
        color = 'danger'
    else:
        color = 'good'

    SUBJECT = f"""CODM Processing Task Status for {prefix}"""

    stack = event['info']['stack']
    domain = event['info']['sesdomain']
    SENDER = f"CODM Processing Task <{stack}@{domain}>"
    SES_REGION = event['info']['sesregion']


    # The email body for recipients with non-HTML email clients.
    BODY_TEXT = (f"CODM Processing Status – {status}\r\n"
                 f"Processing for {prefix}\r\nConsole - https://s3.console.aws.amazon.com/s3/buckets/{bucket}?region={REGION}&prefix={collect}/&showversions=false"
                )

    # The HTML body of the email.
    BODY_HTML = f"""<html>
    <head></head>
    <body>
      <h1>CODM Processing Status – {status} </h1>
      <pre>{prefix}</pre>
      <p>
          <a href="https://s3.console.aws.amazon.com/s3/buckets/{bucket}?region={REGION}&prefix={collect}/&showversions=false">Console View</a>
      </p>
    </body>
    </html>
                """

    # The character encoding for the email.
    CHARSET = "UTF-8"

    # Create a new SES resource and specify a region.
    client = boto3.client('ses',region_name=SES_REGION)
    logger.debug(f'Sending email to {addresses} {type(addresses)}')

    # Try to send the email.
    try:
        #Provide the contents of the email.
        response = client.send_email(
            Destination={
                'ToAddresses': addresses,
            },
            Message={
                'Body': {
                    'Html': {
                        'Charset': CHARSET,
                        'Data': BODY_HTML,
                    },
                    'Text': {
                        'Charset': CHARSET,
                        'Data': BODY_TEXT,
                    },
                },
                'Subject': {
                    'Charset': CHARSET,
                    'Data': SUBJECT,
                },
            },
            Source=SENDER,
        )
    # Display an error if something goes wrong.
    except ClientError as e:

        logger.debug(e.response['Error']['Message'])
    else:
        logger.debug("Email sent! Message ID:"),
        logger.debug(response['MessageId'])




def notify(event, context):

    info = get_job_info(context)
    event['info'] = info # keep this around for our event
    logger.debug(f'notifying for job {info}')

    # Notify Slack
    # Check if we have a slack-hook tag on our lambda
    slack_url = info['slack']
    if slack_url:
        notify_slack(slack_url, event, context)

    message = event
    bucket = message['detail']['parameters']['bucketname']
    collect = message['detail']['parameters']['collectname']
    output = message['detail']['parameters']['outputname']

    collect = collect.lstrip('/')
    uri = os.path.join('s3://', bucket, collect, 'settings.yaml')
    settings = S3Path.from_uri(uri)

    # if set have a settings file and there is an array
    # of email addresses in the notifications top-level key, send email
    logger.debug(f'checking prefix for job {settings}')
    if settings.is_file():
        with settings.open() as f:
            config = yaml.load(f, Loader=yaml.FullLoader)

        logger.debug(f'fetched yaml config {config}')

        # if no notifications list set in the config, we skip
        try:
            config['notifications']
        except KeyError:
            return

        notify_email(config['notifications'], event, context)



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


