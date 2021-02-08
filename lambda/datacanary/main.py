import boto3
import os
import json
from datetime import datetime, date, timedelta

class DateRange:

  def __init__(self, start, end):
    self._start = start
    self._end = end

  @property
  def start(self):
    return datetime.combine(self._start, datetime.min.time())

  @property
  def end(self):
    return datetime.combine(self._end, datetime.max.time())

class PutMetricFetcher:

  def __init__(self, client):
    self._client = client

  def get_daily_put_counts(self, bucket_name, time_range):
    response = self._client.get_metric_data(
        MetricDataQueries=[
            {
                'Id': 'data_bucket_puts',
                'MetricStat': {
                    'Metric': {
                        'Namespace': 'AWS/S3',
                        'MetricName': 'PutRequests',
                        'Dimensions': [
                            {
                                'Name': 'BucketName',
                                'Value': bucket_name
                            },
                            {
                                'Name': 'FilterId',
                                'Value': 'EntireBucket'
                            },
                        ]
                    },
                    'Period': 86400,
                    'Stat': 'Sum',
                },
            },
        ],
        StartTime=time_range.start,
        EndTime=time_range.end,
      )
    daily_put_counts = response["MetricDataResults"][0]["Values"]
    return daily_put_counts


def last_seven_days():
  today = date.today()
  return DateRange(
    start = today - timedelta(days=7),
    end =today
  )


def monitor_object_puts(event, context):
  cloudwatch_client = boto3.client('cloudwatch')
  sns_client = boto3.client('sns')
  sns_topic_arn = os.environ["SNS_TOPIC_ARN"]

  bucket_name = os.environ["BUCKET_NAME"]

  metric_fetcher = PutMetricFetcher(cloudwatch_client)

  daily_put_counts = metric_fetcher.get_daily_put_counts(bucket_name, last_seven_days())
  total_counts = int(sum(daily_put_counts))

  if (total_counts == 0):
      message = {
        "AlarmName": f"Failed data canary: {bucket_name}",
        "AlarmDescription": f"There have been no objects added to bucket {bucket_name} in the last seven days."
      }
      print(message)

      sns_client.publish(
        TopicArn=sns_topic_arn,
        Message=json.dumps({'default': json.dumps(message)}),
        MessageStructure='json'
      )
  else:
    return f"SNS notification not sent since there have been {total_counts} objects added to the bucket {bucket_name} in the last seven days."
