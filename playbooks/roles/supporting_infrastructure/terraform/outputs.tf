output "bastion_instance" {
  value = aws_instance.bastion
}

output "support_instance" {
  value = aws_instance.support
}

output "registry_instance" {
  value = aws_instance.registry
}

output "bastion_eip" {
  value = aws_eip.bastion
}

output "bastion_route53_record" {
  value = aws_route53_record.bastion
}
