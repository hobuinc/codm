resource "aws_cloudwatch_event_rule" "batch-watch" {
    name = "${var.prefix}-batch-event-watcher"
    description = "Watch for changes in given AWS Batch Queue"
    event_pattern = jsonencode({
        source = ["aws.batch"]
        detail-type = [ "Batch Job State Change" ]
        detail = {
            parameters = {
                bucketname = ["${var.prefix}-${var.stage}-codm"]
                }
            status = ["FAILED","STARTING","SUBMITTED","SUCCEEDED"]
        }
    })
}

resource "aws_cloudwatch_event_target" "event-sns-target" {
    rule = aws_cloudwatch_event_rule.batch-watch.name
    target_id = "BatchTopic"
    arn = aws_lambda_function.notify_lambda_function.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_notify" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.notify_lambda_function.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.batch-watch.arn
}

resource "aws_sns_topic" "codm-notifications-sns" {
    name = "${var.prefix}-${var.stage}-notifications"
    display_name = "Cloud ODM Processing Topic"
    tags = {
      Name = "${var.prefix}:sns.${var.stage}.notifications"
    }
}

resource "aws_sns_topic_policy" "batch-watch-policy" {
    arn = aws_sns_topic.codm-notifications-sns.arn
    policy = data.aws_iam_policy_document.sns-topic-policy.json
}

data "aws_iam_policy_document" "sns-topic-policy" {
  policy_id = "${var.prefix}-${var.stage}-sns-watcher-policy"

  statement {
    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_sns_topic.codm-notifications-sns.arn
    ]
    sid = "${var.prefix}-sns-topic-statement-id"
  }
}


