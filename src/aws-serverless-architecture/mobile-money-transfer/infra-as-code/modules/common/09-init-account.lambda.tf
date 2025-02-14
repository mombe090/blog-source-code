locals {
  init_account_name = "init-user-account"
}

data "aws_iam_policy_document" "init_account_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "init_account_lambda_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${local.init_account_name}:*"
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
      "dynamodb:PutItem",
    ]

    resources = [
      aws_dynamodb_table.this.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:DeleteMessage",
    ]

    resources = [
      aws_sqs_queue.this.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
    ]

    resources = [
      aws_ssm_parameter.sms_provider_credentials.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ses:SendEmail",
    ]

    resources = compact([
        var.apply_custom_domain ? aws_ses_domain_identity.domain_identity[0].arn : "",
      aws_ses_email_identity.email_identity.arn
    ])
  }
}

resource "aws_iam_policy" "init_account_lambda_policy" {
  name   = "${local.init_account_name}-policy"
  policy = data.aws_iam_policy_document.init_account_lambda_policy_document.json
}

resource "aws_iam_role" "init_account_lambda_role" {
  name               = "${local.init_account_name}-role"
  assume_role_policy = data.aws_iam_policy_document.init_account_lambda_assume_role.json
}

resource "aws_iam_policy_attachment" "init_account_lambda_policy_attachment" {
  name       = "${local.init_account_name}-policy-attachment"
  roles      = [aws_iam_role.init_account_lambda_role.name]
  policy_arn = aws_iam_policy.init_account_lambda_policy.arn
}

resource "aws_lambda_function" "init_account_lambda" {
  filename      = "${path.module}/dist/${local.init_account_name}.zip"
  function_name = local.init_account_name
  role          = aws_iam_role.init_account_lambda_role.arn
  handler       = "app.lambdaHandler"

  source_code_hash = filebase64sha256("${path.module}/dist/${local.init_account_name}.zip")

  runtime = "nodejs22.x"

  environment {
    variables = {
      aws_region                                  = var.aws_region
      TABLE_NAME                                  = aws_dynamodb_table.this.name,
      SMS_PROVIDER_API_CREDENTIALS_PARAMETER_NAME = aws_ssm_parameter.sms_provider_credentials.name,
      ENABLE_SMS_NOTIFICATIONS                    = var.enable_sms_notifications,
      ENABLE_EMAIL_NOTIFICATIONS                  = var.enable_email_notifications,
      DOMAIN_NAME                                 = var.domain,
      DESTINATION_EMAIL_EMAIL                     = var.test_destination_email,
      APPLY_CUSTOM_DOMAIN                         = var.apply_custom_domain,
      POWERTOOLS_LOG_LEVEL                        = "DEBUG"
    }
  }
}

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn = aws_sqs_queue.this.arn
  function_name    = aws_lambda_function.init_account_lambda.arn
}

resource "aws_lambda_permission" "allow_sqs_to_invoke_lambda" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.init_account_lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.this.arn
}
