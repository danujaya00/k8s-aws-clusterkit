# IAM Role for Kubernetes Master
resource "aws_iam_role" "k8s_master_role" {
  name = "K8sMaster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM Policies for Kubernetes Master
resource "aws_iam_role_policy" "k8s_master_policy" {
  name   = "K8sMasterPolicy"
  role   = aws_iam_role.k8s_master_role.id
  policy = file("policies/k8s_master_policy.json")
}

# IAM Instance Profile for Kubernetes Master
resource "aws_iam_instance_profile" "k8s_master_instance_profile" {
  name = "K8sMaster"
  role = aws_iam_role.k8s_master_role.name
}

# IAM Role for Kubernetes Node
resource "aws_iam_role" "k8s_node_role" {
  name = "K8sNode"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM Policies for Kubernetes Node
resource "aws_iam_role_policy" "k8s_node_policy" {
  name   = "K8sNodePolicy"
  role   = aws_iam_role.k8s_node_role.id
  policy = file("policies/k8s_node_policy.json")
}

# IAM Instance Profile for Kubernetes Node
resource "aws_iam_instance_profile" "k8s_node_instance_profile" {
  name = "K8sNode"
  role = aws_iam_role.k8s_node_role.name
}
