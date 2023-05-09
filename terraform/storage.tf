resource "aws_s3_bucket" "storage" {
    bucket = "${var.prefix}-${var.stage}-codm"

    depends_on = [
      aws_lambda_function.cancel_lambda_function,
      aws_lambda_function.dispatch_lambda_function,
    ]

    tags = {
      Name = "${var.prefix}:s3.${var.stage}"
    }
}


data "aws_iam_policy_document" "topic" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:s3-event-notification-topic"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.storage.arn]
    }
  }
}

resource "aws_sns_topic" "topic" {
  name   = "s3-event-notification-topic"
  policy = data.aws_iam_policy_document.topic.json
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.storage.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.cancel_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = "cancel"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.dispatch_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = "process"
  }
  depends_on = [
    aws_lambda_permission.allow_bucket_dispatch,
    aws_lambda_permission.allow_bucket_cancel,
  ]
}

resource "aws_lambda_permission" "allow_bucket_dispatch" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dispatch_lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.storage.arn
}

resource "aws_lambda_permission" "allow_bucket_cancel" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cancel_lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.storage.arn
}
