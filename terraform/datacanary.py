import boto3
import os
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

def generate_message(count, bucket_name):
  if count <= 0:
    return  (
      f"Failed data canary: {bucket_name}",
      f"There have been no objects added to bucket {bucket_name} in the last seven days"
    )
  else:
    return (
      f"Succesful data canary: {bucket_name}",
      f"There have been {count} objects added to bucket {bucket_name} in the last seven days"
    )

def monitor_object_puts(event, context):
  cloudwatch_client = boto3.client('cloudwatch')
  sns_client = boto3.client('sns')
  sns_topic_arn = os.environ["sns_topic_arn"]

  bucket_name = os.environ["bucket_name"]

  metric_fetcher = PutMetricFetcher(cloudwatch_client)

  daily_put_counts = metric_fetcher.get_daily_put_counts(bucket_name, last_seven_days())
  total_counts = int(sum(daily_put_counts))
  subject, message = generate_message(total_counts, bucket_name)

  print(subject, message)

  sns_client.publish(
    TopicArn=sns_topic_arn,
    Message=message,
    Subject=subject,
  )

