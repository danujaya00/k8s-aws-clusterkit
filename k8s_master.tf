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

resource "null_resource" "copy_script" {
  depends_on = [aws_instance.k8s_master]

  provisioner "file" {
    source      = "master_update_token.sh"
    destination = "/home/ubuntu/master_update_token.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /root/scripts",
      "sudo mv /home/ubuntu/master_update_token.sh /root/scripts/master_update_token.sh",
      "sudo chmod +x /root/scripts/master_update_token.sh",
      "sudo /root/scripts/master_update_token.sh"
    ]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.k8s_key.private_key_pem
    host        = aws_instance.k8s_master.private_ip

    # Use the Bastion Host as an SSH Proxy
    bastion_host        = aws_instance.bastion_host.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = tls_private_key.k8s_key.private_key_pem
  }

}
