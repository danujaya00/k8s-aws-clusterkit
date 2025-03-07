
terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 🔹 VPC Module
module "vpc" {
  source   = "./modules/vpc"
  region   = var.region
  vpc_cidr = "10.0.0.0/16"

}

# 🔹 Security Groups Module
module "security_groups" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
}

# 🔹 IAM Module
module "iam" {
  source     = "./modules/iam"
  account_id = data.aws_caller_identity.current.account_id
}

# 🔹 SSH Key Pair Module
module "ssh" {
  source = "./modules/ssh"
}

# 🔹 EC2 Instances Module
module "ec2" {
  source               = "./modules/ec2"
  general_ami_id       = "ami-04b4f1a9cf54c11d0"
  master_instance_type = "t2.medium"
  worker_instance_type = "t2.micro"

  master_subnet_id           = module.vpc.private_subnet_id
  worker_subnet_id           = module.vpc.private_subnet_id
  bastion_subnet_id          = module.vpc.public_subnet_id
  worker_vpc_zone_identifier = module.vpc.worker_vpc_zone_identifier

  security_group_master  = [module.security_groups.security_group_master]
  security_group_worker  = [module.security_groups.security_group_worker]
  security_group_bastion = [module.security_groups.security_group_bastion]
  security_group_ami     = [module.security_groups.security_group_ami]

  master_iam_instance_profile = module.iam.master_instance_profile
  worker_iam_instance_profile = module.iam.worker_instance_profile

  ssh_key_name    = module.ssh.ssh_key_name
  ami_private_key = module.ssh.private_key

  cluster_name = var.cluster_name
}
