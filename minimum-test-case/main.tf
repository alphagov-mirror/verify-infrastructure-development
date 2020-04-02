terraform {
  required_version = "= 0.12.19"
}

provider "aws" {
  region = "eu-west-2"
}

variable "volume_size" {
  default = 100
}

data "aws_availability_zones" "opted-in" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_iam_role" "volume-mount-test" {
  name               = "volume-mount-test"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "volume-mount-test" {
  role       = aws_iam_role.volume-mount-test.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "volume-mount-test" {
  name = "volume-mount-test"
  role = aws_iam_role.volume-mount-test.name
}

data "aws_ami" "ubuntu_bionic" {
  most_recent = true
  # canonical
  owners = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

data "template_file" "cloud-init" {
  template = file("files/cloud-init.sh")

  vars = {
    volume_size = var.volume_size
  }
}

module "vpc" {
  source       = "JamesWoolfenden/vpc/aws"
  version      = "0.1.21"
  cidr         = "10.0.0.0/21"
  zone         = ["A", "B", "C"]
  common_tags  = { application = "volume-mount-test" }
  account_name = "volume-mount-test"
}

resource "aws_instance" "volume-mount-test" {
  count = 3
  ami                    = data.aws_ami.ubuntu_bionic.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnets[count.index]
  iam_instance_profile   = aws_iam_instance_profile.volume-mount-test.name
  user_data              = data.template_file.cloud-init.rendered
  vpc_security_group_ids = []
  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "volume-mount-test-${count.index}"
  }
}

resource "aws_ebs_volume" "volume-mount-test" {
  count = 3
  size              = var.volume_size
  encrypted         = true
  availability_zone = data.aws_availability_zones.opted-in.names[count.index]
}

resource "aws_volume_attachment" "volume-mount-test" {
  count = 3
  device_name = "/dev/xvdp"
  volume_id   = aws_ebs_volume.volume-mount-test.*.id[count.index]
  instance_id = aws_instance.volume-mount-test.*.id[count.index]
}
