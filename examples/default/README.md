# Nomad Enteprise HVD - Default Example

This example will deploy Nomad Servers and Clients on the same node for a lab or demo environment. This example should not be used in a real world deployment.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.64 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_nomad"></a> [nomad](#module\_nomad) | ../.. | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_friendly_name_prefix"></a> [friendly\_name\_prefix](#input\_friendly\_name\_prefix) | Friendly name prefix used for uniquely naming AWS resources. | `string` | n/a | yes |
| <a name="input_instance_subnets"></a> [instance\_subnets](#input\_instance\_subnets) | List of AWS subnet IDs for instance(s) to be deployed into. | `list(string)` | n/a | yes |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | SSH key name, already registered in AWS, to use for instance access | `string` | n/a | yes |
| <a name="input_lb_subnet_ids"></a> [lb\_subnet\_ids](#input\_lb\_subnet\_ids) | List of subnet IDs to use for the load balancer. If `lb_is_internal` is `false`, then these should be public subnets. Otherwise, these should be private subnets. | `list(string)` | n/a | yes |
| <a name="input_nomad_client"></a> [nomad\_client](#input\_nomad\_client) | Boolean to enable the Nomad client agent. | `bool` | n/a | yes |
| <a name="input_nomad_datacenter"></a> [nomad\_datacenter](#input\_nomad\_datacenter) | Specifies the data center of the local agent. A datacenter is an abstract grouping of clients within a region. Clients are not required to be in the same datacenter as the servers they are joined with, but do need to be in the same region. | `string` | n/a | yes |
| <a name="input_nomad_server"></a> [nomad\_server](#input\_nomad\_server) | Boolean to enable the Nomad server agent. | `bool` | n/a | yes |
| <a name="input_nomad_tls_ca_bundle_secret_arn"></a> [nomad\_tls\_ca\_bundle\_secret\_arn](#input\_nomad\_tls\_ca\_bundle\_secret\_arn) | ARN of AWS Secrets Manager secret for private/custom TLS Certificate Authority (CA) bundle in PEM format. Secret must be stored as a base64-encoded string. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where Nomad will be deployed. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the AWS VPC resources are deployed into. | `string` | n/a | yes |
| <a name="input_additional_package_names"></a> [additional\_package\_names](#input\_additional\_package\_names) | List of additional repository package names to install | `set(string)` | `[]` | no |
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | List of AWS security group IDs to apply to all cluster nodes. | `list(string)` | `[]` | no |
| <a name="input_asg_health_check_grace_period"></a> [asg\_health\_check\_grace\_period](#input\_asg\_health\_check\_grace\_period) | The amount of time to wait for a new Nomad EC2 instance to become healthy. If this threshold is breached, the ASG will terminate the instance and launch a new one. | `number` | `600` | no |
| <a name="input_associate_public_ip"></a> [associate\_public\_ip](#input\_associate\_public\_ip) | Whether public IPv4 addresses should automatically be attached to cluster nodes. | `bool` | `false` | no |
| <a name="input_autopilot_health_enabled"></a> [autopilot\_health\_enabled](#input\_autopilot\_health\_enabled) | Whether autopilot upgrade migration validation is performed for server nodes at boot-time | `bool` | `true` | no |
| <a name="input_cidr_allow_ingress_nomad"></a> [cidr\_allow\_ingress\_nomad](#input\_cidr\_allow\_ingress\_nomad) | List of CIDR ranges to allow ingress traffic on port 443 or 80 to Nomad server or load balancer. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_cni_version"></a> [cni\_version](#input\_cni\_version) | Version of CNI plugin to install. | `string` | `"1.6.0"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Map of common tags for taggable AWS resources. | `map(string)` | `{}` | no |
| <a name="input_create_nlb"></a> [create\_nlb](#input\_create\_nlb) | Boolean to create a Network Load Balancer for Nomad. | `bool` | `true` | no |
| <a name="input_create_route53_nomad_dns_record"></a> [create\_route53\_nomad\_dns\_record](#input\_create\_route53\_nomad\_dns\_record) | Boolean to create Route53 Alias Record for `nomad_hostname` resolving to Load Balancer DNS name. If `true`, `route53_hosted_zone_nomad` is also required. | `bool` | `false` | no |
| <a name="input_data_ebs_iops"></a> [data\_ebs\_iops](#input\_data\_ebs\_iops) | Amount of IOPS to configure when EBS volume type is `gp3`. Must be greater than or equal to `3000` and less than or equal to `16000`. | `number` | `3000` | no |
| <a name="input_data_ebs_throughput"></a> [data\_ebs\_throughput](#input\_data\_ebs\_throughput) | Throughput (MB/s) to configure when data EBS volume type is `gp3`. Must be greater than or equal to `125` and less than or equal to `1000`. | `number` | `250` | no |
| <a name="input_data_ebs_volume_size"></a> [data\_ebs\_volume\_size](#input\_data\_ebs\_volume\_size) | Size (GB) of the data EBS volume for Nomad EC2 instances. Must be greater than or equal to `50` and less than or equal to `16000`. | `number` | `50` | no |
| <a name="input_data_ebs_volume_type"></a> [data\_ebs\_volume\_type](#input\_data\_ebs\_volume\_type) | EBS volume type for data Nomad EC2 instances vol. | `string` | `"gp3"` | no |
| <a name="input_ebs_is_encrypted"></a> [ebs\_is\_encrypted](#input\_ebs\_is\_encrypted) | Boolean to encrypt the EBS root block device of the Nomad EC2 instance(s). An AWS managed key will be used when `true` unless a value is also specified for `ebs_kms_key_arn`. | `bool` | `true` | no |
| <a name="input_ebs_kms_key_arn"></a> [ebs\_kms\_key\_arn](#input\_ebs\_kms\_key\_arn) | ARN of KMS customer managed key (CMK) to encrypt Nomad EC2 EBS volumes. | `string` | `null` | no |
| <a name="input_ec2_allow_ssm"></a> [ec2\_allow\_ssm](#input\_ec2\_allow\_ssm) | Boolean to attach the `AmazonSSMManagedInstanceCore` policy to the Nomad instance role, allowing the SSM agent (if present) to function. | `bool` | `false` | no |
| <a name="input_ec2_ami_id"></a> [ec2\_ami\_id](#input\_ec2\_ami\_id) | AMI to launch ASG instances from. | `string` | `null` | no |
| <a name="input_ec2_os_distro"></a> [ec2\_os\_distro](#input\_ec2\_os\_distro) | Linux OS distribution type for Nomad EC2 instance. Choose from `al2023`, `ubuntu`, `rhel`, `centos`. | `string` | `"ubuntu"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type to launch. | `string` | `"m5.large"` | no |
| <a name="input_lb_is_internal"></a> [lb\_is\_internal](#input\_lb\_is\_internal) | Boolean to create an internal (private) load balancer. The `lb_subnet_ids` must be private subnets when this is `true`. | `bool` | `true` | no |
| <a name="input_nomad_acl_enabled"></a> [nomad\_acl\_enabled](#input\_nomad\_acl\_enabled) | Boolean to enable ACLs for Nomad. | `bool` | `true` | no |
| <a name="input_nomad_architecture"></a> [nomad\_architecture](#input\_nomad\_architecture) | Architecture of the Nomad binary to install. | `string` | `"amd64"` | no |
| <a name="input_nomad_fqdn"></a> [nomad\_fqdn](#input\_nomad\_fqdn) | Fully qualified domain name of the Nomad Cluster. This name should resolve to the load balancer IP address and will be what admins will use to access Nomad. | `string` | `null` | no |
| <a name="input_nomad_gossip_encryption_key_secret_arn"></a> [nomad\_gossip\_encryption\_key\_secret\_arn](#input\_nomad\_gossip\_encryption\_key\_secret\_arn) | ARN of AWS Secrets Manager secret for Nomad gossip encryption key. | `string` | `null` | no |
| <a name="input_nomad_license_secret_arn"></a> [nomad\_license\_secret\_arn](#input\_nomad\_license\_secret\_arn) | ARN of AWS Secrets Manager secret for Nomad license file. | `string` | `null` | no |
| <a name="input_nomad_nodes"></a> [nomad\_nodes](#input\_nomad\_nodes) | Number of Nomad nodes to deploy. | `number` | `6` | no |
| <a name="input_nomad_region"></a> [nomad\_region](#input\_nomad\_region) | Specifies the region of the local agent. A region is an abstract grouping of datacenters. Clients are not required to be in the same region as the servers they are joined with, but do need to be in the same datacenter. If not specified, the region is set AWS region. | `string` | `null` | no |
| <a name="input_nomad_tls_cert_secret_arn"></a> [nomad\_tls\_cert\_secret\_arn](#input\_nomad\_tls\_cert\_secret\_arn) | ARN of AWS Secrets Manager secret for Nomad TLS certificate in PEM format. Secret must be stored as a base64-encoded string. | `string` | `null` | no |
| <a name="input_nomad_tls_enabled"></a> [nomad\_tls\_enabled](#input\_nomad\_tls\_enabled) | Boolean to enable TLS for Nomad. | `bool` | `true` | no |
| <a name="input_nomad_tls_privkey_secret_arn"></a> [nomad\_tls\_privkey\_secret\_arn](#input\_nomad\_tls\_privkey\_secret\_arn) | ARN of AWS Secrets Manager secret for Nomad TLS private key in PEM format. Secret must be stored as a base64-encoded string. | `string` | `null` | no |
| <a name="input_nomad_ui_enabled"></a> [nomad\_ui\_enabled](#input\_nomad\_ui\_enabled) | Boolean to enable the Nomad UI. | `bool` | `true` | no |
| <a name="input_nomad_upstream_servers"></a> [nomad\_upstream\_servers](#input\_nomad\_upstream\_servers) | List of Nomad server addresses to join the Nomad client with. | `list(string)` | `null` | no |
| <a name="input_nomad_upstream_tag_key"></a> [nomad\_upstream\_tag\_key](#input\_nomad\_upstream\_tag\_key) | String of the tag key the Nomad client should look for in AWS to join with. Only needed for auto-joining the Nomad client. | `string` | `null` | no |
| <a name="input_nomad_upstream_tag_value"></a> [nomad\_upstream\_tag\_value](#input\_nomad\_upstream\_tag\_value) | String of the tag value the Nomad client should look for in AWS to join with. Only needed for auto-joining the Nomad client. | `string` | `null` | no |
| <a name="input_nomad_version"></a> [nomad\_version](#input\_nomad\_version) | Version of Nomad to install. | `string` | `"1.9.0+ent"` | no |
| <a name="input_permit_all_egress"></a> [permit\_all\_egress](#input\_permit\_all\_egress) | Whether broad (0.0.0.0/0) egress should be permitted on cluster nodes. If disabled, additional rules must be added to permit HTTP(S) and other necessary network access. | `bool` | `true` | no |
| <a name="input_root_ebs_iops"></a> [root\_ebs\_iops](#input\_root\_ebs\_iops) | Amount of IOPS to configure when root EBS volume type is `gp3`. Must be greater than or equal to `3000` and less than or equal to `16000`. | `number` | `3000` | no |
| <a name="input_root_ebs_throughput"></a> [root\_ebs\_throughput](#input\_root\_ebs\_throughput) | Throughput (MB/s) to configure when root EBS volume type is `gp3`. Must be greater than or equal to `125` and less than or equal to `1000`. | `number` | `250` | no |
| <a name="input_root_ebs_volume_size"></a> [root\_ebs\_volume\_size](#input\_root\_ebs\_volume\_size) | Size (GB) of the root EBS volume for Nomad EC2 instances. Must be greater than or equal to `50` and less than or equal to `16000`. | `number` | `50` | no |
| <a name="input_root_ebs_volume_type"></a> [root\_ebs\_volume\_type](#input\_root\_ebs\_volume\_type) | EBS volume type for root Nomad EC2 instances vol. | `string` | `"gp3"` | no |
| <a name="input_route53_nomad_hosted_zone_is_private"></a> [route53\_nomad\_hosted\_zone\_is\_private](#input\_route53\_nomad\_hosted\_zone\_is\_private) | Boolean indicating if `route53_nomad_hosted_zone_name` is a private hosted zone. | `bool` | `false` | no |
| <a name="input_route53_nomad_hosted_zone_name"></a> [route53\_nomad\_hosted\_zone\_name](#input\_route53\_nomad\_hosted\_zone\_name) | Route53 Hosted Zone name to create `nomad_hostname` Alias record in. Required if `create_nomad_alias_record` is `true`. | `string` | `null` | no |
<!-- END_TF_DOCS -->
