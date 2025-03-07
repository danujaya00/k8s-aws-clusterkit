# Create EC2 instance for AMI creation
resource "aws_instance" "k8s_ami_instance" {

  # Depends on the Bastion Host, Nat Gateway & Security Group
  depends_on = [
    aws_instance.bastion_host,
    var.internet_gateway_id,
    var.nat_gateway_id

  ]

  ami                    = var.general_ami_id
  instance_type          = var.worker_instance_type
  key_name               = var.ssh_key_name
  subnet_id              = var.worker_subnet_id
  vpc_security_group_ids = var.security_group_ami
  iam_instance_profile   = var.worker_iam_instance_profile

  # Provisioning with Cloud-Init
  user_data = file("${path.root}/scripts/cloud-init-k8s.sh")

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
    aws_instance.bastion_host
  ]
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.ami_private_key
      host        = aws_instance.k8s_ami_instance.private_ip

      # Use the Bastion Host as an SSH Proxy
      bastion_host        = aws_instance.bastion_host.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = var.ami_private_key
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
