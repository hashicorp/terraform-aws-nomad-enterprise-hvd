# Deployment Customizations

This page contains various deployment customizations related to creating your Nomad infrastructure and their corresponding module input variables that you may configure to meet your specific requirements where the default module values do not suffice. All of the module input variables mentioned on this page are optional.

## Load Balancing

### Load Balancer Type

This module currently supports creating a Network Load Balancer (NLB) in front of the Nomad autoscaling group. By default, an NLB is provisioned, and there is no option to switch to an ALB (Application Load Balancer) at this time.

### Load Balancer Scheme

This module allows you to create a load balancer with either an `internal` or `internet-facing` load balancing scheme. **The default is `internal`**, but you can configure the load balancer to be `internet-facing` (public) by setting the following module boolean input variable:

```hcl
lb_is_internal = false
```
## Custom AMI

By default, this module will use the standard AWS Marketplace image based on the value of the `ec2_os_distro` input (either `ubuntu`, `rhel`, or `al2023`). If you prefer to use your own custom AMI, you can set `ec2_ami_id` accordingly.

To use a custom AWS AMI, you can specify it using the following module input variables:

```hcl
ec2_os_distro = "<rhel>"
ec2_ami_id    = "<custom-rhel-ami-id>"
```

By default, the `templates/install_nomad.sh.tpl` script will attempt to install the required software dependencies:

- `aws-cli` (and `unzip`, a dependency for installing it)
- `nomad` 

If your Nomad EC2 instances won’t have egress connectivity to official package repositories, you should pre-bake these dependencies into your custom AMI.