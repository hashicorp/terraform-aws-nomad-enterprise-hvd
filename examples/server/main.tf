# Copyright IBM Corp. 2025
# SPDX-License-Identifier: MPL-2.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.64"
    }
  }
}

provider "aws" {
  region = var.region
}

module "nomad" {
  source = "../.."

  # --- Common --- #
  friendly_name_prefix = var.friendly_name_prefix
  common_tags          = var.common_tags
  region               = var.region

  # --- Bootstrap --- #
  nomad_license_secret_arn               = var.nomad_license_secret_arn
  nomad_gossip_encryption_key_secret_arn = var.nomad_gossip_encryption_key_secret_arn
  nomad_tls_cert_secret_arn              = var.nomad_tls_cert_secret_arn
  nomad_tls_privkey_secret_arn           = var.nomad_tls_privkey_secret_arn
  nomad_tls_ca_bundle_secret_arn         = var.nomad_tls_ca_bundle_secret_arn

  # --- Compute --- #
  instance_type                 = var.instance_type
  key_name                      = var.key_name
  ec2_ami_id                    = var.ec2_ami_id
  nomad_nodes                   = var.nomad_nodes
  asg_health_check_grace_period = var.asg_health_check_grace_period
  ec2_allow_ssm                 = var.ec2_allow_ssm

  # --- Networking --- #
  additional_security_group_ids = var.additional_security_group_ids
  permit_all_egress             = var.permit_all_egress
  vpc_id                        = var.vpc_id
  associate_public_ip           = var.associate_public_ip
  autopilot_health_enabled      = var.autopilot_health_enabled
  instance_subnets              = var.instance_subnets
  lb_is_internal                = var.lb_is_internal
  lb_subnet_ids                 = var.lb_subnet_ids
  cidr_allow_ingress_nomad      = var.cidr_allow_ingress_nomad
  create_nlb                    = var.create_nlb

  # --- Nomad config settings --- #
  nomad_version            = var.nomad_version
  nomad_tls_enabled        = var.nomad_tls_enabled
  nomad_client             = var.nomad_client
  nomad_server             = var.nomad_server
  nomad_datacenter         = var.nomad_datacenter
  nomad_region             = var.nomad_region
  nomad_ui_enabled         = var.nomad_ui_enabled
  nomad_upstream_servers   = var.nomad_upstream_servers
  nomad_acl_enabled        = var.nomad_acl_enabled
  nomad_upstream_tag_key   = var.nomad_upstream_tag_key
  nomad_upstream_tag_value = var.nomad_upstream_tag_value

  # --- DNS --- #
  create_route53_nomad_dns_record      = var.create_route53_nomad_dns_record
  route53_nomad_hosted_zone_name       = var.route53_nomad_hosted_zone_name
  route53_nomad_hosted_zone_is_private = var.route53_nomad_hosted_zone_is_private
  nomad_fqdn                           = var.nomad_fqdn
}
