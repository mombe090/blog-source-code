locals {
  init_user_account_queue_name = "init-user-account"
}

resource "aws_sqs_queue" "this" {
  name = local.init_user_account_queue_name
  #todo
}

data "aws_iam_policy_document" "init_user_account_queue_policy_document" {
  statement {
    sid    = uuidv5("dns", "init-user-account-queue-policy-document")
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_lambda_function.get_account_info.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.id
  policy    = data.aws_iam_policy_document.init_user_account_queue_policy_document.json
}
