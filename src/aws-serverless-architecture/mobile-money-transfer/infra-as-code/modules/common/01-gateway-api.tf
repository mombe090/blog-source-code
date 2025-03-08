locals {
  api_gw_name = "fintech-solution-api"
  get_acount_info_lambda_name = "get-account-info"
}

data "aws_iam_policy_document" "api_gw_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "api_gw_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:${local.get_acount_info_lambda_name}"
    ]
  }
}

data "template_file" "endpoints" {
  template = file("${path.module}/templates/endpoints.oas.yaml")

  vars = {
    api_gateway_role_arn        = aws_iam_role.gateway_rest_api_role.arn
    jwt_authorizer_lambda_arn   = aws_lambda_function.lambda_authorizer.arn
    get_account_info_lambda_arn = "arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:${local.get_acount_info_lambda_name}"
    aws_region                  = var.aws_region
  }
}

resource "aws_iam_role" "gateway_rest_api_role" {
  name               = "${local.api_gw_name}-role"
  assume_role_policy = data.aws_iam_policy_document.api_gw_assume_role.json
}

resource "aws_iam_policy" "api_gw_policy" {
  name   = "${local.api_gw_name}-policy"
  policy = data.aws_iam_policy_document.api_gw_policy_document.json
}

resource "aws_iam_policy_attachment" "api_gw_policy_attachment" {
  name = "${local.api_gw_name}-policy-attachment"
  roles = [
    aws_iam_role.gateway_rest_api_role.name
  ]
  policy_arn = aws_iam_policy.api_gw_policy.arn
}


resource "aws_api_gateway_rest_api" "this" {
  body = data.template_file.endpoints.rendered

  name = local.api_gw_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "dev"
}

resource "aws_api_gateway_domain_name" "this" {
  count = var.apply_custom_domain ? 1 : 0

  domain_name              = "api.${var.domain}"
  regional_certificate_arn = aws_acm_certificate.this[0].arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  depends_on = [aws_acm_certificate.this, aws_acm_certificate_validation.this]
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.apply_custom_domain ? 1 : 0

  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
}

