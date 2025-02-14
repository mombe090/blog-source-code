locals {
  get_account_info_name = "get-account-info"
}

data "aws_iam_policy_document" "get_account_info_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "get_account_info_lambda_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${local.get_account_info_name}:*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      aws_kms_key.this.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
    ]

    resources = [
      aws_dynamodb_table.this.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage",
    ]

    resources = [
      aws_sqs_queue.this.arn
    ]
  }
}

resource "aws_iam_policy" "get_account_info_lambda_policy" {
  name   = "${local.get_account_info_name}-policy"
  policy = data.aws_iam_policy_document.get_account_info_lambda_policy_document.json
}

resource "aws_iam_role" "get_account_info_lambda_role" {
  name               = "${local.get_account_info_name}-role"
  assume_role_policy = data.aws_iam_policy_document.get_account_info_lambda_assume_role.json
}

resource "aws_iam_policy_attachment" "get_account_info_lambda_policy_attachment" {
  name       = "${local.get_account_info_name}-policy-attachment"
  roles      = [aws_iam_role.get_account_info_lambda_role.name]
  policy_arn = aws_iam_policy.get_account_info_lambda_policy.arn
}

resource "aws_lambda_function" "get_account_info" {
  filename      = "${path.module}/dist/get-account-info.zip"
  function_name = local.get_account_info_name
  role          = aws_iam_role.get_account_info_lambda_role.arn
  handler       = "app.lambdaHandler"

  source_code_hash = filebase64sha256("${path.module}/dist/get-account-info.zip")

  runtime = "nodejs22.x"

  environment {
    variables = {
      aws_region             = var.aws_region
      TABLE_NAME             = aws_dynamodb_table.this.name,
      INIT_ACCOUNT_QUEUE_URL = aws_sqs_queue.this.url
      POWERTOOLS_LOG_LEVEL   = "DEBUG"
    }
  }
}
