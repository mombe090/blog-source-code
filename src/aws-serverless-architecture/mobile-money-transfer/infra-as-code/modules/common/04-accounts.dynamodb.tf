resource "aws_dynamodb_table" "this" {
  name         = "user-account-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "msisdn" # numéro de telephone

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.this.arn
  }

  attribute {
    name = "msisdn"
    type = "S"
  }
}
