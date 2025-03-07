# Security Group for Kubernetes Nodes
resource "aws_security_group" "k8s_ami_sg" {
  name        = "k8s-ami"
  description = "Kubernetes AMI Instances"
  vpc_id      = aws_vpc.ec2_cluster_vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
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


# Security Group for Kubernetes Master Node
resource "aws_security_group" "k8s_master_sg" {
  name        = "k8s-master"
  description = "Kubernetes Master Hosts"
  vpc_id      = aws_vpc.ec2_cluster_vpc.id

  # Allow SSH from Bastion Host
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Kubernetes API Server (6443) access from private subnet
  ingress {
    description = "K8s API server from private subnet"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Kubelet communication from private subnet
  ingress {
    description = "Worker Nodes Kubelet Communication"
    from_port   = 10250
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Cilium VXLAN ports (8472 UDP)
  ingress {
    description = "Cilium Networking"
    from_port   = 8472
    to_port     = 8475
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow ICMP (ping)
  ingress {
    description = "ICMP ping from private subnet"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow all outbound traffic
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


# Security Group for Kubernetes Worker Nodes
resource "aws_security_group" "k8s_worker_node_sg" {
  name        = "k8s-worker-node-sg"
  description = "Kubernetes Worker Nodes"
  vpc_id      = aws_vpc.ec2_cluster_vpc.id

  # SSH from Bastion Host
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # Allow Kubernetes API Server responses from master node subnet
  ingress {
    description = "K8s API server responses"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # DNS from master subnet
  ingress {
    description = "DNS TCP from master subnet"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "DNS UDP from master subnet"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Kubelet API from master
  ingress {
    description = "Kubelet API and metrics from Master"
    from_port   = 10250
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Inter-node traffic (for Cilium & cluster communication)
  ingress {
    description = "All traffic between nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # ICMP from subnet
  ingress {
    description = "ICMP from subnet"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-nodes-sg"
  }
}
