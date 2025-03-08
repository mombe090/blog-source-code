data "aws_route53_zone" "this" {
  count = var.apply_custom_domain ? 1 : 0

  name         = var.domain
  private_zone = false #todo change to true if you are using a private hosted zone
}

resource "aws_route53_record" "this" {
  count = var.apply_custom_domain ? 1 : 0

  name    = "api.${var.domain}"
  type    = "A"
  zone_id = data.aws_route53_zone.this[0].zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.this[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.this[0].regional_zone_id
  }
}

resource "aws_acm_certificate" "this" {
  count = var.apply_custom_domain ? 1 : 0

  domain_name               = "api.${var.domain}"
  subject_alternative_names = ["api.${var.domain}"]
  validation_method         = "DNS"
}

resource "aws_acm_certificate_validation" "this" {
  count = var.apply_custom_domain ? 1 : 0

  certificate_arn   = aws_acm_certificate.this[0].arn
}