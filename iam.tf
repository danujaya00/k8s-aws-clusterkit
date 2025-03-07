#* Roles For Master Node *#

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
  name = "K8sMasterPolicy"
  role = aws_iam_role.k8s_master_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "K8sMasterDescribeResources"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
      },
      {
        Sid    = "K8sMasterAllResourcesWriteable"
        Effect = "Allow"
        Action = [
          "ec2:CreateRoute",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:ModifyInstanceAttribute"
        ]
        Resource = "*"
      },
      {
        Sid    = "K8sMasterTaggedResourcesWritable"
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DeleteRoute",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteVolume",
          "ec2:DetachVolume",
          "ec2:RevokeSecurityGroupIngress"
        ]
        Resource = "*"
      },
      {
        Sid    = "K8sMasterSSMParameterReadWrite"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/kubeadm/*"
        ]
      }
    ]
  })
}

# IAM Instance Profile for Kubernetes Master
resource "aws_iam_instance_profile" "k8s_master_instance_profile" {
  name = "K8sMaster"
  role = aws_iam_role.k8s_master_role.name
}

#* Roles For Worker Nodes *#

# IAM Role for Kubernetes Node
resource "aws_iam_role" "k8s_node_role" {
  name = "K8sNode"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole",
      Sid       = ""
    }]
  })
}

# IAM Policies for Kubernetes Node
resource "aws_iam_role_policy" "k8s_node_policy" {
  name = "K8sNodePolicy"
  role = aws_iam_role.k8s_node_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "K8sNodeDescribeResources"
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances", "ec2:DescribeRegions"]
        Resource = "*"
      },
      {
        Sid    = "K8sNodeSSMAccess"
        Effect = "Allow"
        Action = ["ssm:GetParameter"]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/kubeadm/*"
        ]
      }
    ]
  })
}


# IAM Instance Profile for Kubernetes Node
resource "aws_iam_instance_profile" "k8s_node_instance_profile" {
  name = "K8sNode"
  role = aws_iam_role.k8s_node_role.name
}
