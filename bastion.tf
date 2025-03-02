# Create a Security Group for the Bastion Host
resource "aws_security_group" "bastion_sg" {
  name        = "ssh-bastion"
  description = "SSH Bastion Hosts"
  vpc_id      = aws_vpc.ec2_cluster_vpc.id

  # Allow SSH access from anywhere (Update to your IP for security)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outgoing traffic from the Bastion
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-bastion-sg"
  }
}

# Create a Bastion Host (EC2 instance)
resource "aws_instance" "bastion_host" {
  ami                         = "ami-04b4f1a9cf54c11d0"
  instance_type               = "t2.micro"
  key_name                    = "aws-kube-cluster"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "ssh-bastion"
  }
}

# Output Bastion Host Public IP
output "bastion_host_public_ip" {
  description = "Public IP of the Bastion Host"
  value       = aws_instance.bastion_host.public_ip
}
