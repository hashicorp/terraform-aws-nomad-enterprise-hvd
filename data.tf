
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

}

data "aws_ami" "provided" {
  count = var.ec2_ami_id != null ? 1 : 0

  filter {
    name   = "image-id"
    values = [var.ec2_ami_id]
  }
}
