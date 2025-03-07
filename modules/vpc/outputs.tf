# output vpc_id 
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.ec2_cluster_vpc.id
}

# output public_subnet_id
output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public_subnet.id
}

# output private_subnet_id
output "private_subnet_id" {
  description = "Private Subnet ID"
  value       = aws_subnet.private_subnet.id
}

# output worker vpc zone identifier
output "worker_vpc_zone_identifier" {
  description = "Worker VPC Zone Identifier"
  value       = [aws_subnet.private_subnet.id]
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat_gw.id
}


