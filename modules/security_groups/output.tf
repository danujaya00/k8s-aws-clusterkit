# master node security group id
output "security_group_master" {
  value = aws_security_group.k8s_master_sg.id
}

# worker node security group id
output "security_group_worker" {
  value = aws_security_group.k8s_worker_node_sg.id
}

# bastion host security group id
output "security_group_bastion" {
  value = aws_security_group.bastion_sg.id
}

# ami creation instance security group id
output "security_group_ami" {
  value = aws_security_group.k8s_ami_sg.id
}
