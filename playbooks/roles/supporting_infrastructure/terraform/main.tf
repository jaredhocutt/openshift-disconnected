terraform {
  backend "s3" {}
}

provider "aws" {}

###############################################################################
# Data
###############################################################################

data "aws_ami" "rhel7" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat

  filter {
    name   = "name"
    values = ["RHEL-7.6_HVM_GA-20190128-x86_64-0-${var.cloud_access_enabled == true ? "Access2" : "Hourly2"}-GP2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

###############################################################################
# VPC
###############################################################################

resource "aws_vpc" "openshift" {
  cidr_block           = "${var.vpc_cidr_block}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_id}"
  }
}

resource "aws_vpc_dhcp_options" "default" {
  domain_name_servers = ["${var.support_private_ip}", "1.1.1.1"]
}

resource "aws_vpc_dhcp_options_association" "default" {
  vpc_id          = "${aws_vpc.openshift.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.default.id}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.openshift.id}"

  tags = {
    Name = "${var.cluster_id}"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.openshift.id}"
  cidr_block              = "${var.private_subnet_cidr_block}"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.cluster_id}-private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.openshift.id}"

  tags = {
    Name = "${var.cluster_id}-private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.openshift.id}"
  cidr_block              = "${var.public_subnet_cidr_block}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_id}-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.openshift.id}"

  tags = {
    Name = "${var.cluster_id}-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route" "default" {
  route_table_id = "${aws_route_table.public.id}"

  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.default.id}"
}

###############################################################################
# Security Groups
###############################################################################

resource "aws_security_group" "ssh" {
  name        = "${var.cluster_id}-ssh"
  description = "${var.cluster_id}-ssh"
  vpc_id      = "${aws_vpc.openshift.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cluster" {
  name        = "${var.cluster_id}-cluster"
  description = "${var.cluster_id}-cluster"
  vpc_id      = "${aws_vpc.openshift.id}"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "cluster_allow_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.cluster.id}"
  self              = true
}

###############################################################################
# EC2 Instances
###############################################################################

resource "aws_instance" "bastion" {
  ami                    = "${data.aws_ami.rhel7.id}"
  instance_type          = "t3.small"
  key_name               = "${var.aws_keypair}"
  subnet_id              = "${aws_subnet.public.id}"
  private_ip             = "${var.bastion_private_ip}"
  vpc_security_group_ids = ["${aws_security_group.cluster.id}", "${aws_security_group.ssh.id}"]

  root_block_device {
    volume_size           = 20
    delete_on_termination = true
  }

  tags = {
    Name = "${var.cluster_id}-bastion"
  }
}

resource "aws_instance" "support" {
  ami                    = "${data.aws_ami.rhel7.id}"
  instance_type          = "t3.medium"
  key_name               = "${var.aws_keypair}"
  subnet_id              = "${aws_subnet.private.id}"
  private_ip             = "${var.support_private_ip}"
  vpc_security_group_ids = ["${aws_security_group.cluster.id}"]

  root_block_device {
    volume_size           = 20
    delete_on_termination = true
  }

  tags = {
    Name = "${var.cluster_id}-support"
  }
}

resource "aws_instance" "registry" {
  ami                    = "${data.aws_ami.rhel7.id}"
  instance_type          = "t3.medium"
  key_name               = "${var.aws_keypair}"
  subnet_id              = "${aws_subnet.private.id}"
  private_ip             = "${var.registry_private_ip}"
  vpc_security_group_ids = ["${aws_security_group.cluster.id}"]

  root_block_device {
    volume_size           = 150
    delete_on_termination = true
  }

  tags = {
    Name = "${var.cluster_id}-registry"
  }
}

###############################################################################
# Elastic IPs
###############################################################################

resource "aws_eip" "bastion" {
  vpc        = true
  instance   = "${aws_instance.bastion.id}"
  depends_on = ["aws_internet_gateway.default"]

  tags = {
    Name = "${var.cluster_id}-bastion"
  }
}

###############################################################################
# DNS Entries
###############################################################################

resource "aws_route53_record" "bastion" {
  zone_id = "${var.route53_hosted_zone_id}"
  name    = "bastion.${var.cluster_name}.${var.base_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.bastion.public_ip}"]
}
