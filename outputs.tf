output "bastion_ssh_private_key" {
  value     = element(tls_private_key.keys.*.private_key_pem, var.server_count)
  sensitive = true
}

output "bastion_ssh_public_key" {
  value = element(tls_private_key.keys.*.public_key_openssh, var.server_count)
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

output "app_instance_private_ips" {
  value = {
    for k, inst in aws_instance.app_servers : k => "ID : ${inst.id} - Private IP: ${inst.private_ip}"
  }
}