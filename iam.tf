# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "gossip_encryption_key" {
  count = var.nomad_gossip_encryption_key_secret_arn != null ? 1 : 0

  statement {
    sid     = "BoundaryDBPassword"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.nomad_gossip_encryption_key_secret_arn,
    ]
  }
}


data "aws_iam_policy_document" "license" {
  count = var.nomad_license_secret_arn != null ? 1 : 0

  statement {
    sid     = "BoundaryLicense"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.nomad_license_secret_arn,
    ]
  }
}

data "aws_iam_policy_document" "tls_cert" {
  count = var.nomad_tls_cert_secret_arn != null ? 1 : 0

  statement {
    sid     = "BoundaryTLSCert"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.nomad_tls_cert_secret_arn,
    ]
  }
}

data "aws_iam_policy_document" "tls_privkey" {
  count = var.nomad_tls_privkey_secret_arn != null ? 1 : 0
  statement {
    sid     = "BoundaryTLSPrivKey"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.nomad_tls_privkey_secret_arn,
    ]
  }
}
data "aws_iam_policy_document" "tls_ca" {
  count = var.nomad_tls_ca_bundle_secret_arn != null ? 1 : 0
  statement {
    sid     = "BoundaryTLSCABundle"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      var.nomad_tls_ca_bundle_secret_arn
    ]
  }
}

data "aws_iam_policy_document" "nomad_discovery" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = [

    var.nomad_license_secret_arn != null ? data.aws_iam_policy_document.license[0].json : "",
    var.nomad_gossip_encryption_key_secret_arn != null ? data.aws_iam_policy_document.gossip_encryption_key[0].json : "",
    var.nomad_tls_cert_secret_arn != null ? data.aws_iam_policy_document.tls_cert[0].json : "",
    var.nomad_tls_privkey_secret_arn != null ? data.aws_iam_policy_document.tls_privkey[0].json : "",
    var.nomad_tls_ca_bundle_secret_arn != null ? data.aws_iam_policy_document.tls_ca[0].json : "",
    data.aws_iam_policy_document.nomad_discovery.json
  ]
}

resource "aws_iam_role_policy" "nomad_ec2" {
  name   = "${var.friendly_name_prefix}-nomad-controller-instance-role-policy-${var.region}"
  role   = aws_iam_role.nomad_ec2.id
  policy = data.aws_iam_policy_document.combined.json
}

resource "aws_iam_role" "nomad_ec2" {
  name = "${var.friendly_name_prefix}-nomad-instance-role-${var.region}"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-nomad-instance-role-${var.region}" },
    var.common_tags
  )
}

resource "aws_iam_instance_profile" "nomad_ec2" {
  name = "${var.friendly_name_prefix}-nomad-${var.region}"
  path = "/"
  role = aws_iam_role.nomad_ec2.name
}

resource "aws_iam_role_policy_attachment" "aws_ssm" {
  count = var.ec2_allow_ssm == true ? 1 : 0

  role       = aws_iam_role.nomad_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
