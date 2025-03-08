data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms_policy_document" {
  statement {
    sid    = uuidv5("dns", "kms_policy_document_root")
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = [
      "*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }
}

resource "aws_kms_key" "this" {
  description = "Cle d'encryption pour les données"
  policy      = data.aws_iam_policy_document.kms_policy_document.json
}

resource "aws_kms_alias" "this" {
  name          = "alias/fintech-solution"
  target_key_id = aws_kms_key.this.key_id
}