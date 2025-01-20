# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Network load balancer (NLB)
#------------------------------------------------------------------------------

locals {
  lb_name_suffix = var.lb_is_internal ? "internal" : "external"
}

resource "aws_lb" "nlb" {
  count = var.create_nlb == true ? 1 : 0

  name               = "${var.friendly_name_prefix}-nomad-nlb-${local.lb_name_suffix}"
  load_balancer_type = "network"
  internal           = var.lb_is_internal
  subnets            = var.lb_subnet_ids

  security_groups = [
    aws_security_group.lb_allow_ingress[0].id,
    aws_security_group.lb_allow_egress[0].id
  ]

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-nomad-nlb-${local.lb_name_suffix}" },
    var.common_tags
  )
}

resource "aws_lb_listener" "nlb_443" {
  count = var.create_nlb && var.nomad_tls_enabled ? 1 : 0

  load_balancer_arn = aws_lb.nlb[0].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_4646[0].arn
  }
}

resource "aws_lb_listener" "nlb_80" {
  count = var.create_nlb == true && var.nomad_tls_enabled == false ? 1 : 0

  load_balancer_arn = aws_lb.nlb[0].arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_4646[0].arn
  }
}

resource "aws_lb_target_group" "nlb_4646" {
  count = var.create_nlb == true ? 1 : 0

  name     = "${var.friendly_name_prefix}-nomad-nlb-tg-4646"
  protocol = "TCP"
  port     = 4646
  vpc_id   = var.vpc_id

  health_check {
    protocol            = var.nomad_tls_enabled ? "HTTPS" : "HTTP"
    path                = "/v1/agent/health"
    port                = "traffic-port"
    matcher             = "200"
    healthy_threshold   = 5
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-nomad-nlb-tg-443" },
    { "Description" = "Load balancer target group for Nomad application traffic." },
    var.common_tags
  )
}

#------------------------------------------------------------------------------
# Load Balancer Security groups
#------------------------------------------------------------------------------
resource "aws_security_group" "lb_allow_ingress" {
  count = var.create_nlb == true ? 1 : 0

  name   = "${var.friendly_name_prefix}-nomad-lb-allow-ingress"
  vpc_id = var.vpc_id

  tags = merge({ "Name" = "${var.friendly_name_prefix}-nomad-lb-allow-ingress" }, var.common_tags)
}

resource "aws_security_group_rule" "lb_allow_ingress_nomad_from_cidr" {
  count = var.create_nlb == true ? 1 : 0

  type        = "ingress"
  from_port   = var.nomad_tls_enabled ? 443 : 80
  to_port     = var.nomad_tls_enabled ? 443 : 80
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_nomad
  description = "Allow TCP/443 (HTTPS) or TCP/80 (HTTP) inbound to Nomad load balancer from specified CIDR ranges."

  security_group_id = aws_security_group.lb_allow_ingress[0].id
}

resource "aws_security_group_rule" "lb_allow_ingress_nomad_from_ec2" {
  count = var.create_nlb == true ? 1 : 0

  type                     = "ingress"
  from_port                = var.nomad_tls_enabled ? 443 : 80
  to_port                  = var.nomad_tls_enabled ? 443 : 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_allow_ingress.id
  description              = "Allow TCP/443 (HTTPS) or TCP/80 (HTTP) inbound to Nomad load balancer from Nomad EC2 security group."

  security_group_id = aws_security_group.lb_allow_ingress[0].id
}

resource "aws_security_group" "lb_allow_egress" {
  count = var.create_nlb == true ? 1 : 0

  name   = "${var.friendly_name_prefix}-nomad-lb-allow-egress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-nomad-lb-allow-egress" }, var.common_tags)
}

resource "aws_security_group_rule" "lb_allow_egress_all" {
  count = var.create_nlb == true ? 1 : 0

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all traffic outbound from the Nomad load balancer."

  security_group_id = aws_security_group.lb_allow_egress[0].id
}
