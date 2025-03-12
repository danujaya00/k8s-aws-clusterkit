# Launch Kubernetes Master Node
resource "aws_instance" "k8s_master" {
  ami                    = aws_ami_from_instance.k8s_ami.id
  instance_type          = "t2.medium"
  key_name               = var.ssh_key_name
  subnet_id              = var.master_subnet_id
  vpc_security_group_ids = var.security_group_master
  iam_instance_profile   = var.master_iam_instance_profile
  private_ip             = var.master_private_ip

  user_data = file("${path.root}/scripts/cloud-init-master.sh")

  tags = {
    Name                                = "ec2-cluster-k8s-master"
    "kubernetes.io/cluster/ec2-cluster" = "owned"
  }

  depends_on = [aws_ami_from_instance.k8s_ami]
}

resource "null_resource" "copy_script" {
  depends_on = [aws_instance.k8s_master]

  provisioner "file" {
    source      = "${path.root}/scripts/master_update_token.sh"
    destination = "/home/ubuntu/master_update_token.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "sudo mkdir -p /root/scripts",
      "sudo mv /home/ubuntu/master_update_token.sh /root/scripts/master_update_token.sh",
      "sudo chmod +x /root/scripts/master_update_token.sh",
      "echo 'Script copied successfully'",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      "echo 'Cloud-init finished'"
    ]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.ami_private_key
    host        = aws_instance.k8s_master.private_ip

    # Use the Bastion Host as an SSH Proxy
    bastion_host        = aws_instance.bastion_host.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = var.ami_private_key
  }
}
