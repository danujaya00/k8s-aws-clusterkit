# Security Group for Kubernetes Nodes
resource "aws_security_group" "k8s_ami_sg" {
  name        = "k8s-ami"
  description = "Kubernetes AMI Instances"
  vpc_id      = aws_vpc.ec2_cluster_vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # Allow SSH only via Bastion
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-ami-sg"
  }
}
