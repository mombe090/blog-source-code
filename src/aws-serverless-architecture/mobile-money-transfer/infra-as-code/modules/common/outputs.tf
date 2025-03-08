output "gateway_api_role" {
  value = {
    name = aws_iam_role.gateway_rest_api_role.name
    arn  = aws_iam_role.gateway_rest_api_role.arn
  }
  description = "Le rôle IAM pour l'API Gateway REST."
}
output "gateway_api_rest" {
  value = {
    name          = aws_api_gateway_rest_api.this.name
    id            = aws_api_gateway_rest_api.this.id
    execution_arn = aws_api_gateway_rest_api.this.execution_arn
    stage_name    = aws_api_gateway_stage.this.stage_name
    domain_name   = var.apply_custom_domain ? aws_api_gateway_domain_name.this[0].domain_name : null
  }

  description = "Les détails de l'API Gateway REST pour l'application."
}

output "route53_record" {
  value = var.apply_custom_domain ? {
    hostname = aws_route53_record.this[0].fqdn
    records  = aws_route53_record.this[0].records
    type     = aws_route53_record.this[0].type
  } : null

  description = "Les détails du record Route 53 pour le domaine personnalisé."
}

output "acm_certificate" {
  value = var.apply_custom_domain ? {
    certificate_arn       = aws_acm_certificate.this[0].arn
    certificate_authority = aws_acm_certificate.this[0].certificate_authority_arn
  } : null

  description = "Les détails du certificat ACM pour le domaine personnalisé."
}

output "lambda_authorizer" {
  value = {
    name               = aws_lambda_function.lambda_authorizer.function_name
    arn                = aws_lambda_function.lambda_authorizer.arn
    execution_role_arn = aws_iam_role.lambda_authorizer_role.arn
  }

  description = "Les détails de la fonction Lambda pour l'autorisation de token."
}

output "dynamo_db_table" {
  value = {
    name = aws_dynamodb_table.this.name
    arn  = aws_dynamodb_table.this.arn
  }

  description = "Les détails de la table DynamoDB pour les utilisateurs."
}

output "init_account_sqs_queue" {
  value = {
    name = aws_sqs_queue.this.name
    arn  = aws_sqs_queue.this.arn
    url  = aws_sqs_queue.this.url
  }

  description = "Les détails de la file d'attente SQS pour les tâches d'initialisation de compte."
}

output "get_account_info_lambda" {
  value = {
    name               = aws_lambda_function.get_account_info.function_name
    arn                = aws_lambda_function.get_account_info.arn
    execution_role_arn = aws_iam_role.get_account_info_lambda_role.arn
  }

  description = "Les détails de la fonction Lambda pour obtenir les informations de compte."
}

output "init_account_lambda" {
  value = {
    name               = aws_lambda_function.init_account_lambda.function_name
    arn                = aws_lambda_function.init_account_lambda.arn
    execution_role_arn = aws_iam_role.init_account_lambda_role.arn
  }

  description = "Les détails de la fonction Lambda pour initialiser les comptes."
}
