
resource "aws_iam_role" "iam_role_for_lambda" {
  name               = "${var.prefix}-lambda-role"
  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Action": "sts:AssumeRole",
           "Principal": {
               "Service": "lambda.amazonaws.com"
           },
           "Effect": "Allow"
       }
   ]

}
 EOF
}

data "aws_iam_policy_document" "iam_for_lambda_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "CreateCloudWatchLogs"
  }

  statement {
    actions = [
        "s3:GetBucketTagging",
        "s3:PutObjectTagging",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject",
        "batch:SubmitJob",
        "lambda:ListTags",
        "batch:List*",
        "batch:Describe*",
        "batch:CancelJob",
        "batch:TerminateJob",
        "sns:Publish",
        "ses:SendEmail",
        "ses:SendRawEmail",
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:GetQueueAttributes",
        "sqs:ListQueues",
        "sqs:SendMessageBatch",
        "sqs:GetQueueUrl",
        "sqs:ListQueueTags",
        "sqs:DeleteMessage",
        "sns:ListSubscriptionsByTopic",
        "sns:Subscribe",
        "sns:Publish",
        "sns:GetTopicAttributes",
        "sns:SetSubscriptionAttributes",
        "sns:GetSubscriptionAttributes"

    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "DoLambdaStuff"
  }

  statement {
    actions = [
      "s3:Get*",
    ]
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.prefix}-${var.stage}-codm", "arn:aws:s3:::${var.prefix}-${var.stage}-codm/*"]
    sid       = "reads3"
  }

}

resource "aws_iam_policy" "iam_for_lambda" {
  name   = "${var.prefix}-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.iam_for_lambda_policy_document.json
}



resource "aws_lambda_function" "notify_lambda_function" {
  function_name = "${var.prefix}-${var.stage}-notify"
  role          = aws_iam_role.iam_role_for_lambda.arn
  handler       = "lambda.handlers.notify"
  runtime       = "python3.9"
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256

  description = "Respond to CODM notifications"
  tags = {
    name = var.prefix
    Name = "${var.prefix}:lambda.${var.stage}.process"
    slackhook = jsondecode(file("${path.root}/config.json")).slackhook
    sesregion = jsondecode(file("${path.root}/config.json")).sesregion
    sesdomain = jsondecode(file("${path.root}/config.json")).sesdomain
    stage = var.stage
  }
  timeout  = var.function_timeout
  filename = data.archive_file.python_lambda_package.output_path
  layers = [aws_lambda_layer_version.lambda_layer.arn]
  depends_on = [
    aws_cloudwatch_log_group.notify_lambda_log,
    data.archive_file.python_lambda_package

  ]

 # vpc_config {
 #   subnet_ids = [ for s in aws_subnet.worker-subnets: s.id ]
 #   security_group_ids = [ aws_security_group.worker-security-group.id ]
 # }
}

# stolen from https://pfertyk.me/2023/02/creating-aws-lambda-functions-with-terraform/

resource "aws_cloudwatch_log_group" "notify_lambda_log" {
  name              = "/aws/lambda/${var.prefix}-${var.stage}-notify"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "cancel_lambda_log" {
  name              = "/aws/lambda/${var.prefix}-${var.stage}-cancel"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "dispatch_lambda_log" {
  name              = "/aws/lambda/${var.prefix}-${var.stage}-dispatch"
  retention_in_days = 14
}


data "aws_iam_policy_document" "lambda_logging_document" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions = [
        "s3:GetBucketTagging",
        "s3:PutObjectTagging",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject",
        "batch:SubmitJob",
        "lambda:ListTags",
        "batch:List*",
        "batch:Describe*",
        "batch:CancelJob",
        "batch:TerminateJob",
        "sns:Publish",
        "ses:SendEmail",
        "ses:SendRawEmail",
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:GetQueueAttributes",
        "sqs:ListQueues",
        "sqs:SendMessageBatch",
        "sqs:GetQueueUrl",
        "sqs:ListQueueTags",
        "sqs:DeleteMessage",
        "sns:ListSubscriptionsByTopic",
        "sns:Subscribe",
        "sns:Publish",
        "sns:GetTopicAttributes",
        "sns:SetSubscriptionAttributes",
        "sns:GetSubscriptionAttributes"

    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "DoLambdaStuff"
  }
}


resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_logging_policy_attachment" {
  role       = aws_iam_role.iam_role_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

resource "aws_lambda_function_event_invoke_config" "notify_invoke" {
  function_name                = aws_lambda_function.notify_lambda_function.function_name
  maximum_retry_attempts       = 0
}

resource "aws_lambda_function_event_invoke_config" "dispatch_invoke" {
  function_name                = aws_lambda_function.dispatch_lambda_function.function_name
  maximum_retry_attempts       = 0
}

resource "aws_lambda_function_event_invoke_config" "cancel_invoke" {
  function_name                = aws_lambda_function.cancel_lambda_function.function_name
  maximum_retry_attempts       = 0
}

resource "aws_lambda_function" "dispatch_lambda_function" {
  function_name = "${var.prefix}-${var.stage}-dispatch"
  role          = aws_iam_role.iam_role_for_lambda.arn
  handler       = "lambda.handlers.dispatch"
  runtime       = "python3.9"
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256

  description = "Dispatch CODM jobs when 'process' file is copied to s3:// prefix"
  tags = {
    name = var.prefix
    Name = "${var.prefix}:lambda.${var.stage}.dispatch"
    stage = var.stage
  }
  timeout  = var.function_timeout
  filename = data.archive_file.python_lambda_package.output_path
  layers = [aws_lambda_layer_version.lambda_layer.arn]
  depends_on = [
    aws_cloudwatch_log_group.dispatch_lambda_log,
    data.archive_file.python_lambda_package
  ]
}

resource "aws_lambda_permission" "dispatch_sns_permission" {
  statement_id  = "ExecuteFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dispatch_lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.prefix}-${var.stage}-codm"
}

resource "aws_lambda_permission" "cancel_sns_permission" {
  statement_id  = "ExecuteFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cancel_lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.prefix}-${var.stage}-codm"
}

resource "aws_lambda_function" "cancel_lambda_function" {
  function_name = "${var.prefix}-${var.stage}-cancel"
  role          = aws_iam_role.iam_role_for_lambda.arn
  handler       = "lambda.handlers.cancel"
  runtime       = "python3.9"
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256

  description = "Cancel CODM jobs when 'cancel' file is copied to s3:// prefix"
  tags = {
    name = var.prefix
    Name = "${var.prefix}:lambda.${var.stage}.cancel"
    stage = var.stage
  }
  timeout  = var.function_timeout
  filename = data.archive_file.python_lambda_package.output_path
  layers = [aws_lambda_layer_version.lambda_layer.arn]
  depends_on = [
    aws_cloudwatch_log_group.cancel_lambda_log,
    data.archive_file.python_lambda_package
  ]
}


resource "aws_iam_role" "lambda-service-role" {
  name = "${var.prefix}-${var.stage}-LambdaServiceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service : "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}


output "notify_function_id" {
  value = "aws_lambda_function.${var.prefix}-${var.stage}-notify.id"
}
output "cancel_function_id" {
  value = "aws_lambda_function.${var.prefix}-${var.stage}-cancel.id"
}

output "dispatch_function_id" {
  value = "aws_lambda_function.${var.prefix}-${var.stage}-dispatch.id"
}


resource "null_resource" "pip_install" {
  triggers = {
    shell_hash = "${sha256(file("${path.root}/requirements.txt"))}"
  }

  provisioner "local-exec" {
    command =  "rm -rf ${path.root}/builds/* && mkdir ${path.root}/builds/python && python3 -m pip install -r requirements.txt -t ${path.root}/builds/python"
  }
}


resource "null_resource" "lambda_code" {
  triggers = {
    python_file = md5(file("${path.root}/lambda/lambda/handlers.py"))
  }
}

data "archive_file" "python_lambda_package" {
  depends_on = [
    null_resource.lambda_code,
    data.archive_file.lambda_layer_zip,
    null_resource.pip_install
  ]
  type        = "zip"
  source_dir = "${path.root}/lambda/"
  output_path = "${path.root}/lambda-functions.zip"
}

data "archive_file" "lambda_layer_zip" {
  type        = "zip"
  source_dir  = "${path.root}/builds"
  output_path = "${path.root}/lambda-layer.zip"
  depends_on  = [null_resource.pip_install]
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name          = "${var.prefix}-${var.stage}-lambda-layer"
  filename            = data.archive_file.lambda_layer_zip.output_path
  source_code_hash    = data.archive_file.lambda_layer_zip.output_base64sha256
  compatible_runtimes = ["python3.9"]
}
