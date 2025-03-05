
# Create EC2 instance for AMI creation
resource "aws_instance" "k8s_ami_instance" {

  # Depends on the Bastion Host, Nat Gateway & Security Group
  depends_on = [
    aws_instance.bastion_host,
    aws_nat_gateway.nat_gw,
    aws_security_group.k8s_ami_sg
  ]
  ami                    = "ami-04b4f1a9cf54c11d0"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.k8s_key.key_name
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.k8s_ami_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.k8s_node_instance_profile.name

  # Provisioning with Cloud-Init
  user_data = file("cloud-init-k8s.sh")

  tags = {
    Name = "kubernetes-node-ami"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Wait for provisioning & instance shutdown before creating the AMI
resource "null_resource" "wait_for_provisioning" {
  depends_on = [aws_instance.k8s_ami_instance,
    aws_instance.bastion_host,
    aws_key_pair.k8s_key,
    local_file.private_key
  ]
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.k8s_key.private_key_pem
      host        = aws_instance.k8s_ami_instance.private_ip

      # Use the Bastion Host as an SSH Proxy
      bastion_host        = aws_instance.bastion_host.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = tls_private_key.k8s_key.private_key_pem
    }

    inline = [
      "echo 'Waiting for Kubernetes setup to complete...'",
      "while [ ! -f /tmp/k8s-setup-done ]; do sleep 10; done",
      "echo 'Setup complete, waiting for instance to shut down...'"
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "Checking if instance is stopped..."
      while true; do
        STATUS=$(aws ec2 describe-instances --instance-ids ${aws_instance.k8s_ami_instance.id} --query 'Reservations[*].Instances[*].State.Name' --output text)
        echo "Current state: $STATUS"
        if [ "$STATUS" = "stopped" ]; then
          echo "Instance is stopped. Proceeding with AMI creation."
          break
        fi
        sleep 10
      done
    EOT
  }
}

# Create an AMI after setup
resource "aws_ami_from_instance" "k8s_ami" {
  name               = "k8s-v1.30"
  source_instance_id = aws_instance.k8s_ami_instance.id
  description        = "Kubernetes v1.30 AMI"

  depends_on = [null_resource.wait_for_provisioning]

  tags = {
    Name = "k8s-ami"
  }
}

# Output the AMI ID
output "k8s_ami_id" {
  description = "The AMI ID for Kubernetes Nodes"
  value       = aws_ami_from_instance.k8s_ami.id
}
