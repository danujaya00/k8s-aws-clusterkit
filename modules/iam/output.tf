output "master_instance_profile" {
  value = aws_iam_instance_profile.k8s_master_instance_profile.name

}

output "master_instance_profile_arn" {
  value = aws_iam_instance_profile.k8s_master_instance_profile.arn
}

output "master_instance_profile_id" {
  value = aws_iam_instance_profile.k8s_master_instance_profile.id
}

output "worker_instance_profile" {
  value = aws_iam_instance_profile.k8s_node_instance_profile.name
}

output "worker_instance_profile_arn" {
  value = aws_iam_instance_profile.k8s_node_instance_profile.arn
}

output "worker_instance_profile_id" {
  value = aws_iam_instance_profile.k8s_node_instance_profile.id
}
