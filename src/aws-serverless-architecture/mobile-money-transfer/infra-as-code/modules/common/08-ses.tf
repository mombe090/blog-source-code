resource "aws_ses_domain_identity" "domain_identity" {
  count = var.apply_custom_domain ? 1 : 0

  domain = var.domain
}

resource "aws_ses_domain_dkim" "this" {
  count = var.apply_custom_domain ? 1 : 0

  domain = aws_ses_domain_identity.domain_identity[0].domain
}

resource "aws_route53_record" "ses_dkim_record" {
  count = var.apply_custom_domain ? 3 : 0

  zone_id = aws_route53_record.this[0].zone_id
  name    = "${aws_ses_domain_dkim.this[0].dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.this[0].dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_ses_domain_identity_verification" "this" {
  count = var.apply_custom_domain ? 1 : 0

  domain     = aws_ses_domain_identity.domain_identity[0].id
  depends_on = [aws_route53_record.ses_dkim_record]
}

resource "aws_ses_email_identity" "email_identity" {
  email = var.test_destination_email
}
