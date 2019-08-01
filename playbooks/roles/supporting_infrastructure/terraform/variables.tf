variable "cluster_id" {
  type        = string
  description = "A cluster ID that is unique to the AWS account (e.g. openshift-example-com)"
}

variable "cluster_name" {
  type        = string
  description = "The name of the OpenShift cluster"
}

variable "base_domain" {
  type        = string
  description = "The base domain of the OpenShift cluster"
}

variable "cloud_access_enabled" {
  type        = bool
  default     = false
  description = "If cloud access is enabled on the AWS account, set to true to prevent being double charged for RHEL"
}

variable "aws_keypair" {
  type        = string
  description = "The name of the AWS keypair to insert into the EC2 instances"
}

variable "route53_hosted_zone_id" {
  type        = string
  description = "The ID of the Route53 hosted zone to create the OpenShift hostnames provided"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR to assign to the VPC"
}

variable "private_subnet_cidr_block" {
  type        = string
  description = "The CIDR to assign to the private subnet"
}

variable "public_subnet_cidr_block" {
  type        = string
  description = "The CIDR to assign to the public subnet"
}

variable "bastion_private_ip" {
  type        = string
  description = "The private IP address for the bastion"
}

variable "support_private_ip" {
  type        = string
  description = "The private IP address for the support host"
}

variable "registry_private_ip" {
  type        = string
  description = "The private IP address for the registry host"
}
