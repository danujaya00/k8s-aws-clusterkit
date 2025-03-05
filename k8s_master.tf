# Security Group for Kubernetes Master Node
resource "aws_security_group" "k8s_master_sg" {
  name        = "k8s-master"
  description = "Kubernetes Master Hosts"
  vpc_id      = aws_vpc.ec2_cluster_vpc.id

  # Allow SSH from Bastion Host only
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Allow K8s API Server (Port 6443) access from worker nodes
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow all outgoing traffic 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-master-sg"
  }
}

# Launch Kubernetes Master Node
resource "aws_instance" "k8s_master" {
  ami                    = aws_ami_from_instance.k8s_ami.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.k8s_key.key_name
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_master_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.k8s_master_instance_profile.name
  private_ip             = "10.0.0.11"

  user_data = file("cloud-init-master.sh")

  tags = {
    Name                                = "ec2-cluster-k8s-master"
    "kubernetes.io/cluster/ec2-cluster" = "owned"
  }

  depends_on = [aws_ami_from_instance.k8s_ami]
}

# Output the private IP of the master node
output "k8s_master_private_ip" {
  description = "Private IP of the Kubernetes Master Node"
  value       = aws_instance.k8s_master.private_ip
}
