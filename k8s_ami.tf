
# Create EC2 instance for AMI creation
resource "aws_instance" "k8s_ami_instance" {
  ami                    = "ami-04b4f1a9cf54c11d0" # Ubuntu 24.04 AMI
  instance_type          = "t2.micro"
  key_name               = "aws-kube-cluster"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_ami_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.k8s_node_instance_profile.name

  # Provisioning with Cloud-Init
  user_data = file("cloud-init-k8s.sh")

  tags = {
    Name = "kubernetes-node-ami"
  }

  # Auto shutdown after provisioning
  lifecycle {
    ignore_changes = [user_data]
  }
}

# Create an AMI after setup
resource "aws_ami_from_instance" "k8s_ami" {
  name               = "k8s-v1.30"
  source_instance_id = aws_instance.k8s_ami_instance.id
  description        = "Kubernetes v1.30 AMI"

  depends_on = [aws_instance.k8s_ami_instance]

  tags = {
    Name = "k8s-ami"
  }
}

# Output the AMI ID
output "k8s_ami_id" {
  description = "The AMI ID for Kubernetes Nodes"
  value       = aws_ami_from_instance.k8s_ami.id
}
