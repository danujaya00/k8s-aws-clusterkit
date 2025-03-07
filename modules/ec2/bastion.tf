# Create a Bastion Host (EC2 instance)
resource "aws_instance" "bastion_host" {
  ami                         = var.general_ami_id
  instance_type               = var.worker_instance_type
  key_name                    = var.ssh_key_name
  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = var.security_group_bastion
  associate_public_ip_address = true

  tags = {
    Name = "ssh-bastion"
  }
}
