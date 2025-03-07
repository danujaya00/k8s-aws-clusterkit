# create a new launch template and autoscaling group for the worker nodes.
resource "aws_launch_template" "k8_worker_lt" {
  name_prefix   = "k8-worker-lt-"
  image_id      = aws_ami_from_instance.k8s_ami.id
  instance_type = var.worker_instance_type
  key_name      = var.ssh_key_name

  iam_instance_profile {
    name = var.worker_iam_instance_profile
  }

  vpc_security_group_ids = var.security_group_worker

  user_data = base64encode(file("${path.root}/scripts/worker_data.sh"))

  lifecycle {
    create_before_destroy = true
  }
}

# Autoscaling group for worker nodes
resource "aws_autoscaling_group" "k8_worker_asg" {
  depends_on = [null_resource.copy_script]

  name_prefix         = "k8-worker-asg-"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 5
  vpc_zone_identifier = var.worker_vpc_zone_identifier
  launch_template {
    id      = aws_launch_template.k8_worker_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "k8-worker-node"
    propagate_at_launch = true
  }

  # Tags for Cluster Autoscaler autodiscovery
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster_name}"
    value               = "1"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
