# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Provider
#------------------------------------------------------------------------------
variable "region" {
  type        = string
  description = "AWS region where Nomad will be deployed."
}

#------------------------------------------------------------------------------
# Common
#------------------------------------------------------------------------------
variable "friendly_name_prefix" {
  type        = string
  description = "Friendly name prefix used for uniquely naming AWS resources."
  validation {
    condition     = length(var.friendly_name_prefix) > 0 && length(var.friendly_name_prefix) < 17
    error_message = "Friendly name prefix must be between 1 and 16 characters."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Map of common tags for taggable AWS resources."
  default     = {}
}

#------------------------------------------------------------------------------
# Prereqs
#------------------------------------------------------------------------------
variable "nomad_license_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for Nomad license file."
  default     = null
}

variable "nomad_gossip_encryption_key_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for Nomad gossip encryption key."
  default     = null
}

variable "nomad_tls_cert_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for Nomad TLS certificate in PEM format. Secret must be stored as a base64-encoded string."
  default     = null
}

variable "nomad_tls_privkey_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for Nomad TLS private key in PEM format. Secret must be stored as a base64-encoded string."
  default     = null
}

variable "nomad_tls_ca_bundle_secret_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret for private/custom TLS Certificate Authority (CA) bundle in PEM format. Secret must be stored as a base64-encoded string."
  default     = null
}

variable "additional_package_names" {
  type        = set(string)
  description = "List of additional repository package names to install"
  default     = []
}

#------------------------------------------------------------------------------
# Nomad Configuration Settings
#------------------------------------------------------------------------------
variable "nomad_acl_enabled" {
  type        = bool
  description = "Boolean to enable ACLs for Nomad."
  default     = true
}

variable "nomad_client" {
  type        = bool
  description = "Boolean to enable the Nomad client agent."
}

variable "nomad_server" {
  type        = bool
  description = "Boolean to enable the Nomad server agent."
}

variable "nomad_region" {
  type        = string
  description = "Specifies the region of the local agent. A region is an abstract grouping of datacenters. Clients are not required to be in the same region as the servers they are joined with, but do need to be in the same datacenter. If not specified, the region is set AWS region."
  default     = null
}

variable "nomad_datacenter" {
  type        = string
  description = "Specifies the data center of the local agent. A datacenter is an abstract grouping of clients within a region. Clients are not required to be in the same datacenter as the servers they are joined with, but do need to be in the same region."
}

variable "nomad_ui_enabled" {
  type        = bool
  description = "Boolean to enable the Nomad UI."
  default     = true
}

variable "nomad_upstream_servers" {
  type        = list(string)
  description = "List of Nomad server addresses to join the Nomad client with."
  default     = null
}

variable "nomad_upstream_tag_key" {
  type        = string
  description = "String of the tag key the Nomad client should look for in AWS to join with. Only needed for auto-joining the Nomad client."
  default     = null
}

variable "nomad_upstream_tag_value" {
  type        = string
  description = "String of the tag value the Nomad client should look for in AWS to join with. Only needed for auto-joining the Nomad client."
  default     = null
}

variable "nomad_tls_enabled" {
  type        = bool
  description = "Boolean to enable TLS for Nomad."
  default     = true
}

variable "autopilot_health_enabled" {
  type        = bool
  default     = true
  description = "Whether autopilot upgrade migration validation is performed for server nodes at boot-time"
}

variable "nomad_version" {
  type        = string
  description = "Version of Nomad to install."
  default     = "1.9.0+ent"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\+ent$", var.nomad_version))
    error_message = "Value must be in the format 'X.Y.Z+ent'."
  }
}

variable "cni_version" {
  type        = string
  description = "Version of CNI plugin to install."
  default     = "1.6.0"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.cni_version))
    error_message = "Value must be in the format 'X.Y.Z'."
  }
}

variable "nomad_architecture" {
  type        = string
  description = "Architecture of the Nomad binary to install."
  default     = "amd64"
  validation {
    condition     = can(regex("^(amd64|arm64)$", var.nomad_architecture))
    error_message = "value must be either 'amd64' or 'arm64'."
  }
}

variable "nomad_fqdn" {
  type        = string
  description = "Fully qualified domain name of the Nomad Cluster. This name should resolve to the load balancer IP address and will be what admins will use to access Nomad."
  default     = null
}

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------
variable "vpc_id" {
  type        = string
  description = "ID of the AWS VPC resources are deployed into."
}

variable "instance_subnets" {
  type        = list(string)
  description = "List of AWS subnet IDs for instance(s) to be deployed into."
}

variable "associate_public_ip" {
  type        = bool
  default     = false
  description = "Whether public IPv4 addresses should automatically be attached to cluster nodes."
}

variable "cidr_allow_ingress_nomad" {
  type        = list(string)
  description = "List of CIDR ranges to allow ingress traffic on port 443 or 80 to Nomad server or load balancer."
  default     = ["0.0.0.0/0"]
}

variable "permit_all_egress" {
  type        = bool
  default     = true
  description = "Whether broad (0.0.0.0/0) egress should be permitted on cluster nodes. If disabled, additional rules must be added to permit HTTP(S) and other necessary network access."
}

variable "additional_security_group_ids" {
  type        = list(string)
  default     = []
  description = "List of AWS security group IDs to apply to all cluster nodes."
}

variable "create_nlb" {
  type        = bool
  description = "Boolean to create a Network Load Balancer for Nomad."
  default     = true
}

variable "lb_is_internal" {
  type        = bool
  description = "Boolean to create an internal (private) load balancer. The `lb_subnet_ids` must be private subnets when this is `true`."
  default     = true
}

variable "lb_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the load balancer. If `lb_is_internal` is `false`, then these should be public subnets. Otherwise, these should be private subnets."
  default     = null
  validation {
    condition     = var.create_nlb ? length(var.lb_subnet_ids) > 0 : true
    error_message = "When creating a Network Load Balancer, `lb_subnet_ids` must be set."
  }
}

variable "create_route53_nomad_dns_record" {
  type        = bool
  description = "Boolean to create Route53 Alias Record for `nomad_hostname` resolving to Load Balancer DNS name. If `true`, `route53_hosted_zone_nomad` is also required."
  default     = false
}

variable "route53_nomad_hosted_zone_name" {
  type        = string
  description = "Route53 Hosted Zone name to create `nomad_hostname` Alias record in. Required if `create_nomad_alias_record` is `true`."
  default     = null
}

variable "route53_nomad_hosted_zone_is_private" {
  type        = bool
  description = "Boolean indicating if `route53_nomad_hosted_zone_name` is a private hosted zone."
  default     = false
}

#------------------------------------------------------------------------------
# Compute
#------------------------------------------------------------------------------
variable "ec2_os_distro" {
  type        = string
  description = "Linux OS distribution type for Nomad EC2 instance. Choose from `al2023`, `ubuntu`, `rhel`, `centos`."
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "rhel", "al2023", "centos"], var.ec2_os_distro)
    error_message = "Valid values are `ubuntu`, `rhel`, `al2023`, or `centos`."
  }
}

variable "ec2_ami_id" {
  type        = string
  description = "AMI to launch ASG instances from."
  default     = null

  validation {
    condition     = try((length(var.ec2_ami_id) > 4 && substr(var.ec2_ami_id, 0, 4) == "ami-"), var.ec2_ami_id == null)
    error_message = "Value must start with \"ami-\"."
  }
}

variable "instance_type" {
  type        = string
  default     = "m5.large"
  description = "EC2 instance type to launch."
}

variable "nomad_nodes" {
  type        = number
  default     = 6
  description = "Number of Nomad nodes to deploy."
}

variable "asg_health_check_grace_period" {
  type        = number
  description = "The amount of time to wait for a new Nomad EC2 instance to become healthy. If this threshold is breached, the ASG will terminate the instance and launch a new one."
  default     = 600
}

variable "ebs_is_encrypted" {
  type        = bool
  description = "Boolean to encrypt the EBS root block device of the Nomad EC2 instance(s). An AWS managed key will be used when `true` unless a value is also specified for `ebs_kms_key_arn`."
  default     = true
}

variable "ebs_kms_key_arn" {
  type        = string
  description = "ARN of KMS customer managed key (CMK) to encrypt Nomad EC2 EBS volumes."
  default     = null

  validation {
    condition     = var.ebs_kms_key_arn != null ? var.ebs_is_encrypted == true : true
    error_message = "`ebs_is_encrypted` must be `true` when specifying a KMS key ARN for EBS volume."
  }
}

variable "root_ebs_volume_type" {
  type        = string
  description = "EBS volume type for root Nomad EC2 instances vol."
  default     = "gp3"

  validation {
    condition     = var.root_ebs_volume_type == "gp3" || var.root_ebs_volume_type == "gp2"
    error_message = "Supported values are `gp3` and `gp2`."
  }
}

variable "root_ebs_volume_size" {
  type        = number
  description = "Size (GB) of the root EBS volume for Nomad EC2 instances. Must be greater than or equal to `50` and less than or equal to `16000`."
  default     = 50

  validation {
    condition     = var.root_ebs_volume_size >= 50 && var.root_ebs_volume_size <= 16000
    error_message = "Value must be greater than or equal to `50` and less than or equal to `16000`."
  }
}

variable "root_ebs_throughput" {
  type        = number
  description = "Throughput (MB/s) to configure when root EBS volume type is `gp3`. Must be greater than or equal to `125` and less than or equal to `1000`."
  default     = 250

  validation {
    condition     = var.root_ebs_throughput >= 125 && var.root_ebs_throughput <= 1000
    error_message = "Value must be greater than or equal to `125` and less than or equal to `1000`."
  }
}

variable "root_ebs_iops" {
  type        = number
  description = "Amount of IOPS to configure when root EBS volume type is `gp3`. Must be greater than or equal to `3000` and less than or equal to `16000`."
  default     = 3000

  validation {
    condition     = var.root_ebs_iops >= 3000 && var.root_ebs_iops <= 16000
    error_message = "Value must be greater than or equal to `3000` and less than or equal to `16000`."
  }
}

variable "data_ebs_volume_type" {
  type        = string
  description = "EBS volume type for data Nomad EC2 instances vol."
  default     = "gp3"

  validation {
    condition     = var.data_ebs_volume_type == "gp3" || var.data_ebs_volume_type == "gp2"
    error_message = "Supported values are `gp3` and `gp2`."
  }
}

variable "data_ebs_volume_size" {
  type        = number
  description = "Size (GB) of the data EBS volume for Nomad EC2 instances. Must be greater than or equal to `50` and less than or equal to `16000`."
  default     = 50

  validation {
    condition     = var.data_ebs_volume_size >= 50 && var.data_ebs_volume_size <= 16000
    error_message = "Value must be greater than or equal to `50` and less than or equal to `16000`."
  }
}

variable "data_ebs_throughput" {
  type        = number
  description = "Throughput (MB/s) to configure when data EBS volume type is `gp3`. Must be greater than or equal to `125` and less than or equal to `1000`."
  default     = 250

  validation {
    condition     = var.data_ebs_throughput >= 125 && var.data_ebs_throughput <= 1000
    error_message = "Value must be greater than or equal to `125` and less than or equal to `1000`."
  }
}

variable "data_ebs_iops" {
  type        = number
  description = "Amount of IOPS to configure when EBS volume type is `gp3`. Must be greater than or equal to `3000` and less than or equal to `16000`."
  default     = 3000

  validation {
    condition     = var.data_ebs_iops >= 3000 && var.data_ebs_iops <= 16000
    error_message = "Value must be greater than or equal to `3000` and less than or equal to `16000`."
  }
}

variable "key_name" {
  type        = string
  description = "SSH key name, already registered in AWS, to use for instance access"
}

variable "ec2_allow_ssm" {
  type        = bool
  description = "Boolean to attach the `AmazonSSMManagedInstanceCore` policy to the Nomad instance role, allowing the SSM agent (if present) to function."
  default     = false
}
