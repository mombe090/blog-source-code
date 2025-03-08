locals {
  authorizer_lambda_name = "lambda-authorizer"
}

data "aws_iam_policy_document" "lambda_authorizer_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_authorizer_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/lambda/${local.authorizer_lambda_name}:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_authorizer_policy" {
  name   = "${local.authorizer_lambda_name}-policy"
  policy = data.aws_iam_policy_document.lambda_authorizer_policy_document.json
}

resource "aws_iam_role" "lambda_authorizer_role" {
  name               = "${local.authorizer_lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_authorizer_assume_role.json
}

resource "aws_iam_policy_attachment" "lambda_authorizer_policy_attachment" {
  name       = "${local.authorizer_lambda_name}-policy-attachment"
  roles      = [aws_iam_role.lambda_authorizer_role.name]
  policy_arn = aws_iam_policy.lambda_authorizer_policy.arn
}

resource "aws_lambda_function" "lambda_authorizer" {
  filename      = "${path.module}/dist/authorizer.zip"
  function_name = local.authorizer_lambda_name
  role          = aws_iam_role.lambda_authorizer_role.arn
  handler       = "app.lambdaHandler"

  source_code_hash = filebase64sha256("${path.module}/dist/authorizer.zip")

  runtime = "nodejs22.x"

  environment {
    variables = {
      ISSUER_URI           = var.issuer_uri,
      JWKS_URI             = var.jwks_uri,
      AUDIENCE             = var.audience,
      POWERTOOLS_LOG_LEVEL = "INFO"
    }
  }
}

resource "aws_lambda_permission" "allow_api_gw_to_invoke_authorizer" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*"
}
