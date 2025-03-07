output "ssh_key_name" {
  value = aws_key_pair.k8s_key.key_name
}

output "private_key" {
  value = tls_private_key.k8s_key.private_key_pem
}

output "public_key" {
  value = tls_private_key.k8s_key.public_key_openssh
}
