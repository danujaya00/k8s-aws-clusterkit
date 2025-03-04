# Generate a new private key for the AWS EC2 instances
resource "tls_private_key" "k8s_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a new key pair for the AWS EC2 instances
resource "aws_key_pair" "k8s_key" {
  key_name   = "aws-kube-cluster-auto"
  public_key = tls_private_key.k8s_key.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "private_key" {
  content         = tls_private_key.k8s_key.private_key_pem
  filename        = "${path.module}/aws-kube-cluster.pem"
  file_permission = "0600"
}
