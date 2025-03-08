resource "aws_ssm_parameter" "sms_provider_credentials" {
  name   = "sms_provider_credentials"
  type   = "String"
  key_id = aws_kms_key.this.id
  value = jsonencode({
    "client_id" : var.sms_provider_client_id
    "client_secret" : var.sms_provider_client_secret
    "url" : var.sms_provider_api_url
  })
}


