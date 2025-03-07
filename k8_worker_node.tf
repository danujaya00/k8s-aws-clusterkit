# create a new launch template and autoscaling group for the worker nodes.
resource "aws_launch_template" "k8_worker_lt" {
  name_prefix   = "k8-worker-lt-"
  image_id      = aws_ami_from_instance.k8s_ami.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.k8s_key.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.k8s_node_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.k8s_worker_node_sg.id]

  user_data = base64encode(file("worker_data.sh"))

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
  vpc_zone_identifier = [aws_subnet.private_subnet.id]

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
