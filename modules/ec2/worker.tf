# create a new launch template and autoscaling group for the worker nodes.
resource "aws_launch_template" "k8_worker_lt" {
  depends_on = [null_resource.copy_script]

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
  depends_on = [null_resource.copy_script,
  aws_launch_template.k8_worker_lt]

  name_prefix         = "k8-worker-asg-"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 5
  vpc_zone_identifier = var.worker_vpc_zone_identifier
  launch_template {
    id      = aws_launch_template.k8_worker_lt.id
    version = aws_launch_template.k8_worker_lt.latest_version
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



resource "null_resource" "test_deployment" {
  depends_on = [aws_instance.k8s_master,
    aws_autoscaling_group.k8_worker_asg,
    null_resource.copy_script,
    aws_autoscaling_group.k8_worker_asg
  ]
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = aws_instance.k8s_master.private_ip
      user        = "ubuntu"
      private_key = var.ami_private_key

      bastion_host        = aws_instance.bastion_host.public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = var.ami_private_key
    }

    inline = [
      "export KUBECONFIG=/etc/kubernetes/admin.conf",
      "desired_node_count=3",
      "echo 'Waiting for all nodes to become Ready...'",
      "while true; do",
      "  total_nodes=$(kubectl get nodes --no-headers | wc -l)",
      "  ready_nodes=$(kubectl get nodes --no-headers | grep -w 'Ready' | wc -l)",
      "  echo \"Ready nodes: $ready_nodes / Total nodes: $total_nodes\"",
      "  if [ $total_nodes -ge $desired_node_count ] && [ $ready_nodes -eq $total_nodes ]; then",
      "    echo 'All nodes are ready.'",
      "    break",
      "  fi",
      "  sleep 10",
      "done",
      # apply nginx ingress controller using helm
      "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx",
      "helm repo update",
      "helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --set controller.service.type=NodePort --set controller.service.nodePorts.http=30080 --set controller.service.nodePorts.https='30443' ",
      "echo 'Ingress controller deployed.'",
      "kubectl wait --for=condition=Available deployment -l app.kubernetes.io/name=ingress-nginx -n ingress-nginx --timeout=300s",
      # Apply the Deployment
      "cat << 'EOF' | kubectl apply -f -",
      "---",
      "apiVersion: apps/v1",
      "kind: Deployment",
      "metadata:",
      "  name: nginx-deployment",
      "  labels:",
      "    app: nginx",
      "spec:",
      "  replicas: 2",
      "  selector:",
      "    matchLabels:",
      "      app: nginx",
      "  template:",
      "    metadata:",
      "      labels:",
      "        app: nginx",
      "    spec:",
      "      containers:",
      "      - name: nginx",
      "        image: nginx:alpine",
      "        ports:",
      "        - containerPort: 80",
      "EOF",

      # Apply the Service
      "cat << 'EOF' | kubectl apply -f -",
      "---",
      "apiVersion: v1",
      "kind: Service",
      "metadata:",
      "  name: nginx-service",
      "spec:",
      "  selector:",
      "    app: nginx",
      "  ports:",
      "  - port: 80",
      "    protocol: TCP",
      "    targetPort: 80",
      "  type: ClusterIP",
      "EOF",

      # Wait for the Deployment to be ready
      "echo 'Waiting for the Deployment to be ready...'",
      "while true; do",
      "  desired_replicas=$(kubectl get deployment nginx-deployment -o jsonpath='{.spec.replicas}')",
      "  ready_replicas=$(kubectl get deployment nginx-deployment -o jsonpath='{.status.readyReplicas}')",
      # set ready replicas to 0 if it is empty
      "  ready_replicas=$${ready_replicas:-0}",
      "  echo \"Ready replicas: $${ready_replicas} / Desired replicas: $${desired_replicas}\"",

      "  if [ $${desired_replicas} -eq $${ready_replicas} ]; then",
      "    echo 'Deployment is ready.'",
      "    break",
      "  fi",

      "  sleep 10",
      "done",

      # Apply the Ingress
      "cat << 'EOF' | kubectl apply -f -",
      "---",
      "apiVersion: networking.k8s.io/v1",
      "kind: Ingress",
      "metadata:",
      "  name: default",
      "spec:",
      "  ingressClassName: nginx",
      "  rules:",
      "  - http:",
      "      paths:",
      "      - path: /",
      "        pathType: Prefix",
      "        backend:",
      "          service:",
      "            name: nginx-service",
      "            port:",
      "              number: 80",
      "EOF",

      "echo 'Test deployment applied.'"
    ]
  }
}

