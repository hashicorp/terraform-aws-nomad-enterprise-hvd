# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "aws_route53_zone" "nomad" {
  count = var.create_route53_nomad_dns_record && var.route53_nomad_hosted_zone_name != null && var.nomad_fqdn != null ? 1 : 0

  name         = var.route53_nomad_hosted_zone_name
  private_zone = var.route53_nomad_hosted_zone_is_private
}

resource "aws_route53_record" "alias_record" {
  count = var.route53_nomad_hosted_zone_name != null && var.create_route53_nomad_dns_record && var.nomad_fqdn != null && var.create_nlb ? 1 : 0

  name    = var.nomad_fqdn
  zone_id = data.aws_route53_zone.nomad[0].zone_id
  type    = "A"

  alias {
    name                   = aws_lb.nlb[0].dns_name
    zone_id                = aws_lb.nlb[0].zone_id
    evaluate_target_health = true
  }
}