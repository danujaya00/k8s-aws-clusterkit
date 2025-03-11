# Output Bastion Host Public IP
output "bastion_host_public_ip" {
  description = "Public IP of the Bastion Host"
  value       = aws_instance.bastion_host.public_ip
}

# Output the AMI ID
output "k8s_ami_id" {
  description = "The AMI ID for Kubernetes Nodes"
  value       = aws_ami_from_instance.k8s_ami.id
}

# Output the private IP of the master node
output "k8s_master_private_ip" {
  description = "Private IP of the Kubernetes Master Node"
  value       = aws_instance.k8s_master.private_ip
}

# autoscaling group name
output "k8_worker_asg_name" {
  description = "Name of the Kubernetes Worker ASG"
  value       = aws_autoscaling_group.k8_worker_asg.name
}
