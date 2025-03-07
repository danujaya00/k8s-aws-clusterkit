
variable "general_ami_id" {
  description = "AMI ID for the base EC2 instance"
}

variable "master_instance_type" {
  description = "Instance type for the Kubernetes master node"
}

variable "worker_instance_type" {
  description = "Instance type for the Kubernetes worker nodes"
}

variable "master_subnet_id" {
  description = "Subnet ID for the Kubernetes master node"
}

variable "worker_subnet_id" {
  description = "Subnet ID for the Kubernetes worker nodes"
}

variable "security_group_master" {
  description = "Security group ID for the Kubernetes master node"
}

variable "security_group_worker" {
  description = "Security group ID for the Kubernetes worker nodes"
}

variable "security_group_bastion" {
  description = "Security group ID for the Bastion host"
}

variable "security_group_ami" {
  description = "Security group ID for the AMI creation"
}

variable "master_iam_instance_profile" {
  description = "IAM instance profile for the EC2 instances"
}

variable "worker_iam_instance_profile" {
  description = "IAM instance profile for the EC2 instances"
}

variable "ssh_key_name" {
  description = "SSH key name for the EC2 instances"
}

variable "bastion_subnet_id" {
  description = "Public Subnet ID"
}

variable "ami_private_key" {
  description = "Private key for the AMI instance"
}

variable "master_private_ip" {
  description = "Private IP address for the Kubernetes master node"
  default     = "10.0.0.11"
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"

}

variable "worker_vpc_zone_identifier" {
  description = "Worker VPC Zone Identifier"
  type        = list(string)
}

variable "internet_gateway_id" {
  description = "Internet Gateway ID"
}

variable "nat_gateway_id" {
  description = "NAT Gateway ID"
}
