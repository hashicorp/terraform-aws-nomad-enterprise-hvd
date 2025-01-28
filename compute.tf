# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# User Data (cloud-init) arguments
#------------------------------------------------------------------------------
locals {

  custom_data_args = {

    # https://developer.hashicorp.com/nomad/docs/configuration

    # prereqs
    nomad_license_secret_arn               = var.nomad_license_secret_arn
    nomad_gossip_encryption_key_secret_arn = var.nomad_gossip_encryption_key_secret_arn
    nomad_tls_cert_secret_arn              = var.nomad_tls_cert_secret_arn == null ? "NONE" : var.nomad_tls_cert_secret_arn
    nomad_tls_privkey_secret_arn           = var.nomad_tls_privkey_secret_arn == null ? "NONE" : var.nomad_tls_privkey_secret_arn
    nomad_tls_ca_bundle_secret_arn         = var.nomad_tls_ca_bundle_secret_arn == null ? "NONE" : var.nomad_tls_ca_bundle_secret_arn
    additional_package_names               = join(" ", var.additional_package_names)

    # Nomad settings
    nomad_version            = var.nomad_version
    systemd_dir              = "/etc/systemd/system",
    nomad_dir_bin            = "/usr/bin",
    cni_dir_bin              = "/opt/cni/bin",
    nomad_dir_config         = "/etc/nomad.d",
    nomad_dir_home           = "/opt/nomad",
    nomad_install_url        = format("https://releases.hashicorp.com/nomad/%s/nomad_%s_linux_%s.zip", var.nomad_version, var.nomad_version, var.nomad_architecture)
    cni_install_url          = format("https://github.com/containernetworking/plugins/releases/download/v%s/cni-plugins-linux-%s-v%s.tgz", var.cni_version, var.nomad_architecture, var.cni_version)
    aws_region               = var.region
    nomad_tls_enabled        = var.nomad_tls_enabled
    nomad_acl_enabled        = var.nomad_acl_enabled
    nomad_client             = var.nomad_client
    nomad_server             = var.nomad_server
    nomad_datacenter         = var.nomad_datacenter
    nomad_region             = var.nomad_region == null ? var.region : var.nomad_region
    nomad_ui_enabled         = var.nomad_ui_enabled
    nomad_upstream_servers   = var.nomad_upstream_servers
    nomad_upstream_tag_key   = var.nomad_upstream_tag_key
    nomad_upstream_tag_value = var.nomad_upstream_tag_value
    nomad_nodes              = var.nomad_nodes
    asg_name                 = local.template_name
    template_name            = local.template_name
    autopilot_health_enabled = var.autopilot_health_enabled
  }

  user_data_template_rendered = templatefile("${path.module}/templates/nomad_custom_data.sh.tpl", local.custom_data_args)
}

#------------------------------------------------------------------------------
# EC2 AMI data sources
#------------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  count = var.ec2_os_distro == "ubuntu" && var.ec2_ami_id == null ? 1 : 0

  owners      = ["099720109477", "513442679011"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "rhel" {
  count = var.ec2_os_distro == "rhel" && var.ec2_ami_id == null ? 1 : 0

  owners      = ["309956199498"]
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*-Hourly2-GP3"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "al2023" {
  count = var.ec2_os_distro == "al2023" && var.ec2_ami_id == null ? 1 : 0

  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

#------------------------------------------------------------------------------
# Launch Template
#------------------------------------------------------------------------------
locals {
  # If an AMI ID is provided via `var.ec2_ami_id`, use it. Otherwise,
  # use the latest AMI for the specified OS distro via `var.ec2_os_distro`.

  ami_id_list = tolist([
    var.ec2_ami_id,
    join("", data.aws_ami.ubuntu.*.image_id),
    join("", data.aws_ami.rhel.*.image_id),
    join("", data.aws_ami.al2023.*.image_id),
  ])
  ami_root_device_name_list = tolist([
    join("", data.aws_ami.provided.*.root_device_name),
    join("", data.aws_ami.ubuntu.*.root_device_name),
    join("", data.aws_ami.rhel.*.root_device_name),
    join("", data.aws_ami.al2023.*.root_device_name),
  ])

  template_name = "${var.friendly_name_prefix}-nomad"
}

data "aws_ami" "provided" {
  count = var.ec2_ami_id != null ? 1 : 0

  filter {
    name   = "image-id"
    values = [var.ec2_ami_id]
  }
}

resource "aws_launch_template" "nomad" {
  name                                 = local.template_name
  update_default_version               = true
  image_id                             = coalesce(local.ami_id_list...)
  instance_type                        = var.instance_type
  key_name                             = var.key_name
  user_data                            = base64gzip(local.user_data_template_rendered)
  instance_initiated_shutdown_behavior = "terminate"

  block_device_mappings {
    device_name = coalesce(local.ami_root_device_name_list...)
    ebs {
      delete_on_termination = true
      iops                  = var.root_ebs_iops
      volume_size           = var.root_ebs_volume_size
      volume_type           = var.root_ebs_volume_type
      encrypted             = var.ebs_is_encrypted
      kms_key_id            = var.ebs_kms_key_arn
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/sdf"
    ebs {
      delete_on_termination = true
      iops                  = var.data_ebs_iops
      volume_size           = var.data_ebs_volume_size
      volume_type           = var.data_ebs_volume_type
      encrypted             = var.ebs_is_encrypted
      kms_key_id            = var.ebs_kms_key_arn
    }
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip
    security_groups = coalesce([
      aws_security_group.nomad_rpc.id,
      aws_security_group.ec2_allow_ingress.id,
      var.permit_all_egress ? aws_security_group.egress[0].id : "",
      ],
      var.additional_security_group_ids
    )
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.nomad_ec2.arn
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      { "Name" = "${var.friendly_name_prefix}-nomad" },
      { "Type" = "autoscaling-group" },
      { "OS_distro" = var.ec2_os_distro },
      var.common_tags
    )
  }

  tags = merge(
    { "Name" = local.template_name },
    var.common_tags
  )
}

resource "aws_placement_group" "nomad" {
  name         = "${var.friendly_name_prefix}-pg"
  strategy     = "spread"
  spread_level = "rack"
  tags         = merge({ "Name" = "${var.friendly_name_prefix}-nomad" }, var.common_tags)
}

#------------------------------------------------------------------------------
# Autoscaling Group
#------------------------------------------------------------------------------
resource "aws_autoscaling_group" "nomad" {
  name                      = local.template_name
  min_size                  = var.nomad_nodes
  max_size                  = var.nomad_nodes * 2
  desired_capacity          = var.nomad_nodes
  #wait_for_elb_capacity     = var.nomad_nodes # Not evaluated for instances without ELB
  #wait_for_capacity_timeout = "1200s"
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = var.create_nlb ? "ELB" : "EC2"
  vpc_zone_identifier       = var.instance_subnets
  placement_group           = aws_placement_group.nomad.id

  launch_template {
    id      = aws_launch_template.nomad.id
    version = "$Latest"
  }

  target_group_arns = var.create_nlb ? [aws_lb_target_group.nlb_4646[0].arn] : null

  tag {
    key                 = "Name"
    value               = "${var.friendly_name_prefix}-nomad"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment-Name"
    value               = "${var.friendly_name_prefix}-nomad"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

#------------------------------------------------------------------------------
# Security Groups
#------------------------------------------------------------------------------
locals {
  nomad_gossip_cidrs = [data.aws_vpc.cluster.cidr_block]
}

data "aws_vpc" "cluster" {
  id = var.vpc_id
}

resource "aws_security_group" "nomad_rpc" {
  name        = "${var.friendly_name_prefix}-nomad-rpc"
  description = "Permit Nomad RPC/serf traffic"
  vpc_id      = data.aws_vpc.cluster.id
  tags        = merge({ "Name" = "${var.friendly_name_prefix}-nomad-rpc-allow-ingress" }, var.common_tags)

  #  Allow Nomad Server API and RPC.
  dynamic "ingress" {
    for_each = var.nomad_server ? [1] : []
    content {
      description = "Nomad Server API"
      from_port   = 4646
      to_port     = 4647
      protocol    = "tcp"
      cidr_blocks = local.nomad_gossip_cidrs
    }
  }

  egress {
    description = "Nomad Server RPC"
    from_port   = 4647
    to_port     = 4647
    protocol    = "tcp"
    cidr_blocks = local.nomad_gossip_cidrs
  }

  #  Allow LAN gossip within trusted subnets.
  ingress {
    description = "Nomad Gossip (TCP)"
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = local.nomad_gossip_cidrs
  }

  egress {
    description = "Nomad Gossip (TCP)"
    from_port   = 4648
    to_port     = 4648
    protocol    = "tcp"
    cidr_blocks = local.nomad_gossip_cidrs
  }

  ingress {
    description = "Nomad Gossip (UDP)"
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = local.nomad_gossip_cidrs
  }
  egress {
    description = "Nomad Gossip (UDP)"
    from_port   = 4648
    to_port     = 4648
    protocol    = "udp"
    cidr_blocks = local.nomad_gossip_cidrs
  }

  #  Allow SSH in from within the VPC
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_allow_ingress" {
  name   = "${var.friendly_name_prefix}-nomad-ec2-allow-ingress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-nomad-ec2-allow-ingress" }, var.common_tags)
}

resource "aws_security_group_rule" "ec2_allow_ingress_nomad_from_lb" {
  count = var.create_nlb ? 1 : 0

  type                     = "ingress"
  from_port                = 4646
  to_port                  = 4646
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_allow_egress[0].id
  description              = "Allow 4646 inbound to Nomad EC2 instance(s) from Nomad load balancer."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_security_group_rule" "ec2_allow_ingress_nomad_from_cidr" {
  count = var.create_nlb == false ? 1 : 0

  type        = "ingress"
  from_port   = 4646
  to_port     = 4646
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_nomad
  description = "Allow 4646 inbound to Nomad EC2 instance(s) from specified CIDRs."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

#------------------------------------------------------------------------------
# General Egress Security Group
# (Optional) Permits all egress traffic.
# Controlled by var.permit_all_egress
#------------------------------------------------------------------------------
resource "aws_security_group" "egress" {
  count       = var.permit_all_egress ? 1 : 0
  name        = "${var.friendly_name_prefix}-egress"
  description = "Permit all egress traffic"
  vpc_id      = data.aws_vpc.cluster.id
  tags        = merge({ "Name" = "${var.friendly_name_prefix}-nomad-allow-egress" }, var.common_tags)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

