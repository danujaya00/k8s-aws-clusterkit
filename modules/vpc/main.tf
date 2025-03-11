#* Create VPC
resource "aws_vpc" "ec2_cluster_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name                                = "ec2-cluster"
    "kubernetes.io/cluster/ec2-cluster" = "shared"
  }
}

#* Create Subnets
# Main Public Subnet
resource "aws_subnet" "public_subnet" {
  depends_on              = [aws_vpc.ec2_cluster_vpc]
  vpc_id                  = aws_vpc.ec2_cluster_vpc.id
  cidr_block              = "10.0.16.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                                = "ec2-cluster-public-1a"
    "kubernetes.io/cluster/ec2-cluster" = "owned"
    "kubernetes.io/role/elb"            = "1"
  }
}

# Lb public subnet
resource "aws_subnet" "lb_subnet" {
  depends_on = [aws_vpc.ec2_cluster_vpc]

  vpc_id                  = aws_vpc.ec2_cluster_vpc.id
  cidr_block              = "10.0.32.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                                = "ec2-cluster-public-1b"
    "kubernetes.io/cluster/ec2-cluster" = "owned"
    "kubernetes.io/role/elb"            = "1"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  depends_on = [aws_vpc.ec2_cluster_vpc]

  vpc_id                  = aws_vpc.ec2_cluster_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name                                = "ec2-cluster-private-1a"
    "kubernetes.io/cluster/ec2-cluster" = "owned"
    "kubernetes.io/role/internal-elb"   = "1"
  }
}

#* Create Internet Gateway
# Internet Gateway
resource "aws_internet_gateway" "igw" {
  depends_on = [aws_vpc.ec2_cluster_vpc]

  vpc_id = aws_vpc.ec2_cluster_vpc.id
  tags = {
    Name = "ec2-cluster-igw"
  }
}

#* Create Route Tables
# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.ec2_cluster_vpc.id

  tags = {
    Name = "ec2-cluster-public"
  }
}

# Route for Public Route Table
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate LB Subnet with Public Route Table
resource "aws_route_table_association" "lb_association" {
  subnet_id      = aws_subnet.lb_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.ec2_cluster_vpc.id

  tags = {
    Name = "ec2-cluster-private"
  }
}

#* Allocate Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

#* Create NAT Gateway in Public Subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "ec2-cluster-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Route for Private Subnet via NAT Gateway
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}
